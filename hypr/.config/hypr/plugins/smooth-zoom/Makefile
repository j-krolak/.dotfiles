# Hyprland plugins are loaded into the compositor's own address space, so this
# has to match the flags Hyprland itself was built with - hence pkg-config
# rather than a hand-written include list, and -std=c++26 to match its headers.
NAME    = smooth-zoom
SRC     = main.cpp
CXXFLAGS += -std=c++26 -fPIC -O2 -Wall -Wno-unused-parameter $(shell pkg-config --cflags hyprland pixman-1 libdrm)

all: $(NAME).so

$(NAME).so: $(SRC)
	$(CXX) -shared $(CXXFLAGS) $(SRC) -o $@

# Loading twice from the same path silently gives you the OLD code back:
# dlclose doesn't drop the library while Hyprland still holds a reference, so
# the next dlopen returns the cached handle. Loading via a uniquely named copy
# is the only reliable way to iterate without restarting the compositor.
reload: $(NAME).so
	-hyprctl plugin unload $$(readlink -f $(NAME).so)
	@tmp=$$(mktemp /tmp/$(NAME)-XXXXXX.so); cp $(NAME).so $$tmp; \
		hyprctl plugin load $$tmp

clean:
	rm -f $(NAME).so

.PHONY: all clean reload
