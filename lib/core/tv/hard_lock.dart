/// Master hard lock for this machine.
///
/// When true, EVERY wall-screen / TV / IR-box network command is cut at the
/// socket level: no magic packet, no NetCast socket, no SSDP, no HTTP push,
/// no ESP32 request, and the local image server never binds — this build
/// neither sends to nor accepts from the café's devices.
///
/// Flip to false ONLY when building the copy that will run on the store
/// machine (there the wall features must stay live).
const bool kHardLockWallNetwork = true;
