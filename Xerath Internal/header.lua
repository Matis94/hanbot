return {
  id = 'Xerathplus',
  name = "Xerath Internal+",
  riot = true,
  flag = {
    text = "Xerath Internal+",
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
