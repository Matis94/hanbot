return {
  id = 'Xerathplus',
  name = "Xerath Addon By Matis",
  riot = true,
  flag = {
    text = "Xerath Addon By Matis",
    color = {
      text = 0xFFEDD7E6,
      background1 = 0xFFEDBBDC,
      background2 = 0x99000000
    }
  },
  load = function()
    return player.charName == 'Xerath'
  end
}
