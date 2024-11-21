{
  virtualisation = {
    cores = 4;
    graphics = false;
    memorySize = 4096;
    # TODO(@connorbaker): Consider using useNixStoreImage if it boosts performance?
    vlans = [ 1 ];
  };
}
