Vendored from https://github.com/dotnet/msbuild/tree/main/src/MSBuild (MIT).

Modified so SDK-style projects (no `xmlns`) validate:
- removed `targetNamespace` and the `msb:` prefix
- `Project` accepts any mix of top-level tags (SDK projects have implicit imports)
- dropped the C++-only `Link`/`ResourceCompile`/`*BuildEvent` entries from `ItemGroupType`/`ItemDefinitionGroupType` (non-deterministic content model without the namespace)
