{
  virtualisation = {
    cores = 2;
    graphics = false;
    memorySize = 2048;
    # TODO(@connorbaker): Consider using useNixStoreImage if it boosts performance?
    vlans = [ 1 ];
  };
}
