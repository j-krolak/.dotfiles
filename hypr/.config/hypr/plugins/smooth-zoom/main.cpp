// smooth-zoom - gives Hyprland's cursor zoom a dead zone with a damped catch-up.
//
// Stock Hyprland offers three camera behaviours and none of them is the one you
// want for presenting (src/output/MonitorZoomController.cpp): the detached
// camera has a dead zone, but it is 90% of the view - so the camera appears not
// to follow at all until it suddenly scrolls 1:1 - while the two attached modes
// have no dead zone whatsoever, either pinning the point under the cursor or
// locking onto every twitch of the mouse.
//
// What's missing is a small dead zone the cursor can wander inside, and a camera
// that glides after it once it leaves. That's what this is: the cursor roams
// freely within a fraction of the view, and beyond it the camera eases toward
// putting the cursor back on the zone's edge.
//
// All three stock behaviours read their target from one private method,
// CMonitorZoomController::getAnchor, so that is the only thing replaced here.
// The transform and the clamping are left untouched, which is why this stays
// short and has one plausible failure mode - Hyprland renaming that method -
// rather than many.
//
// Needs cursor:zoom_rigid = true and cursor:zoom_detached_camera = false, which
// lua/core/presenting.lua sets by itself when it sees this plugin loaded. Rigid
// is what makes the returned anchor the centre of the view, which the dead zone
// maths below assumes.
//
// Tunable live, since this is all feel:
//   hl.plugin.smooth_zoom.set_follow(0.12)  seconds to close ~63% of the gap
//   hl.plugin.smooth_zoom.set_zone(0.30)    dead zone, as a fraction of the
//                                           visible half-extent

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/output/MonitorZoomController.hpp>
#include <hyprland/src/output/Monitor.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <unordered_map>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
}

inline HANDLE         PHANDLE       = nullptr;
inline CFunctionHook* g_pZoomHook    = nullptr;

// Resolved rather than hooked: these two are how the damped anchor gets into a
// controller whose own getAnchor is inlined out of reach.
inline void (*g_pinAnchor)(void*, const Vector2D&) = nullptr;
inline void (*g_clearAnchor)(void*)                = nullptr;

// Time constant of the chase, in seconds: how long the camera takes to close
// ~63% of the distance to its target. Small enough and it's rigid mode with
// extra steps; large enough and the camera feels like it's on a rope.
inline double g_followTau = 0.12;

// Half-width of the dead zone, as a fraction of the visible half-extent, so it
// scales with the zoom instead of swallowing the whole view at 4x. Hyprland's
// own dead zone is effectively 0.9, which is why its camera feels like it never
// follows until it suddenly does.
inline double g_deadZone = 0.30;

// Diagnostics for hl.plugin.smooth_zoom.stats() - telling "the zone is too big"
// apart from "the hook never ran" is otherwise guesswork.
inline unsigned long long g_calls = 0, g_bailed = 0;
inline double             g_lastZoom = 0, g_lastZoneX = 0, g_lastDX = 0;

using origApplyZoom = void (*)(void*, CBox&, const Render::SRenderData&);

namespace {
    struct SCamera {
        Vector2D                              pos;
        std::chrono::steady_clock::time_point last;
    };

    // Keyed on the controller, which Hyprland owns one of per monitor, so each
    // screen chases independently.
    std::unordered_map<void*, SCamera> g_cameras;
}

static void hkApplyZoomTransform(void* thisptr, CBox& monbox, const Render::SRenderData& rd) {
    const auto ORIGINAL = (origApplyZoom)g_pZoomHook->m_original;

    g_calls++;

    const auto MON = rd.pMonitor.lock();
    if (!MON || !MON->m_cursorZoom) {
        g_bailed++;
        return ORIGINAL(thisptr, monbox, rd);
    }

    const double ZOOM = MON->m_cursorZoom->value();
    if (ZOOM <= 1.0) {
        g_bailed++;
        return ORIGINAL(thisptr, monbox, rd);
    }

    const Vector2D CURSOR = g_pInputManager->getMouseCoordsInternal() - MON->m_position;
    const auto     NOW    = std::chrono::steady_clock::now();
    auto&          cam    = g_cameras[thisptr];

    if (cam.last == std::chrono::steady_clock::time_point{})
        cam.pos = CURSOR;
    else {
        const double DT = std::chrono::duration<double>(NOW - cam.last).count();

        // Rigid mode centres the view on the anchor, so the visible area is
        // the anchor plus/minus this, and the dead zone is a fraction of it.
        const Vector2D HALF = MON->m_size / (2.0 * ZOOM);
        const Vector2D ZONE = HALF * g_deadZone;

        // The whole camera, in one line per axis: how far the cursor is PAST
        // the dead zone. Zero inside it, and growing from zero as it leaves, so
        // the camera engages without a step - there is no target to snap to and
        // no branch to fall off.
        //
        // Easing this to zero parks the cursor on the zone's edge and keeps it
        // there, which is what makes it settle when you stop and trail with a
        // little slack when you don't. An earlier version eased toward
        // recentring the cursor instead; that made every excursion a full sweep
        // across the view, so the zone either did nothing or did everything.
        const Vector2D D      = CURSOR - cam.pos;
        const Vector2D EXCESS = {std::copysign(std::max(0.0, std::abs(D.x) - ZONE.x), D.x),
                                 std::copysign(std::max(0.0, std::abs(D.y) - ZONE.y), D.y)};

        // Frame-rate independent, and it does double duty: this only runs while
        // zoomed, so the gap since the last zoom makes DT huge and the camera
        // snaps instead of gliding in from wherever it was left.
        const double ALPHA = g_followTau > 0.0 ? 1.0 - std::exp(-DT / g_followTau) : 1.0;

        cam.pos = cam.pos + EXCESS * ALPHA;

        // The original clamps the rendered box to the desktop anyway. Clamping
        // the anchor too keeps the two in agreement - otherwise the camera keeps
        // chasing past the edge, and coming back starts with a dead stretch
        // while it unwinds that invisible overshoot.
        if (MON->m_size.x > 2 * HALF.x)
            cam.pos.x = std::clamp(cam.pos.x, HALF.x, MON->m_size.x - HALF.x);
        if (MON->m_size.y > 2 * HALF.y)
            cam.pos.y = std::clamp(cam.pos.y, HALF.y, MON->m_size.y - HALF.y);

        g_lastZoom  = ZOOM;
        g_lastZoneX = ZONE.x;
        g_lastDX    = D.x;
    }

    cam.last = NOW;

    // The controller's own getAnchor is inlined into the original below, so it
    // can't be hooked - but it still reads the pinned anchor out of the object,
    // and pinAnchor is a real exported symbol. So: pin, let the original do all
    // the transform and clamping maths untouched, unpin.
    g_pinAnchor(thisptr, cam.pos);
    ORIGINAL(thisptr, monbox, rd);
    g_clearAnchor(thisptr);
}

// hl.plugin.smooth_zoom.set_follow(seconds) - tuning this is pure feel, and
// recompiling to try 0.08 instead of 0.10 would be absurd.
static int luaSetFollow(lua_State* L) {
    g_followTau = lua_tonumber(L, 1);
    return 0;
}

// hl.plugin.smooth_zoom.set_zone(fraction)
static int luaSetZone(lua_State* L) {
    g_deadZone = std::clamp(lua_tonumber(L, 1), 0.0, 0.95);
    return 0;
}

// hl.plugin.smooth_zoom.stats() -> calls, bailouts, zoom, zoneX, lastDX
static int luaStats(lua_State* L) {
    lua_pushnumber(L, sc<double>(g_calls));
    lua_pushnumber(L, sc<double>(g_bailed));
    lua_pushnumber(L, g_lastZoom);
    lua_pushnumber(L, g_lastZoneX);
    lua_pushnumber(L, g_lastDX);
    return 5;
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    // The loaded-into Hyprland's build string vs. the one compiled into this
    // .so. A plugin runs inside the compositor's address space, so a mismatch
    // here is a crash later rather than an error.
    if (std::string{__hyprland_api_get_hash()} != std::string{__hyprland_api_get_client_hash()}) {
        HyprlandAPI::addNotification(PHANDLE, "[smooth-zoom] built against a different Hyprland, refusing to load",
                                     CHyprColor{1.0, 0.2, 0.2, 1.0}, 5000);
        throw std::runtime_error("[smooth-zoom] version mismatch");
    }

    auto resolve = [&](const std::string& name, const std::string& mustContain) -> void* {
        for (auto& m : HyprlandAPI::findFunctionsByName(handle, name)) {
            if (m.demangled.contains(mustContain))
                return m.address;
        }
        return nullptr;
    };

    const auto APPLY = resolve("applyZoomTransform", "CMonitorZoomController");
    g_pinAnchor      = (void (*)(void*, const Vector2D&))resolve("pinAnchor", "CMonitorZoomController");
    g_clearAnchor    = (void (*)(void*))resolve("clearAnchor", "CMonitorZoomController");

    if (!APPLY || !g_pinAnchor || !g_clearAnchor) {
        HyprlandAPI::addNotification(PHANDLE, "[smooth-zoom] could not resolve CMonitorZoomController symbols", CHyprColor{1.0, 0.2, 0.2, 1.0}, 5000);
        throw std::runtime_error("[smooth-zoom] symbol resolution failed");
    }

    g_pZoomHook = HyprlandAPI::createFunctionHook(handle, APPLY, (void*)&hkApplyZoomTransform);

    if (!g_pZoomHook || !g_pZoomHook->hook()) {
        HyprlandAPI::addNotification(PHANDLE, "[smooth-zoom] could not hook applyZoomTransform", CHyprColor{1.0, 0.2, 0.2, 1.0}, 5000);
        throw std::runtime_error("[smooth-zoom] hook failed");
    }

    HyprlandAPI::addLuaFunction(handle, "smooth_zoom", "set_follow", &luaSetFollow);
    HyprlandAPI::addLuaFunction(handle, "smooth_zoom", "set_zone", &luaSetZone);
    HyprlandAPI::addLuaFunction(handle, "smooth_zoom", "stats", &luaStats);

    return {"smooth-zoom", "Damped camera for the cursor zoom", "jakub", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_cameras.clear();
}
