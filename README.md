# swadge-vrchat-bridge

# System Overview

![System Overview](https://github.com/cnlohr/swadge-vrchat-bridge/blob/master/system_diagram.png?raw=true)

# Editing


 * Open Project
 * Add VRCSDK3-WORLD-2022.02.16.19.13_Public.unitypackage
 * Add UdonSharp_v0.20.3.unitypackage
 * Add CyanEmu.v0.3.10
 * Add AudioLink-0.2.8
 
Close and re-open Unity.

1. Compile the swadge firmware.
2. Point the `Makefile` In the `swadgesandbox` to point at that swadge firmware. 
3. Type `make` in `swadgesandbox` to run the correct firmware on the swadge.
4. Run the bridge app in `bridgeapp`
