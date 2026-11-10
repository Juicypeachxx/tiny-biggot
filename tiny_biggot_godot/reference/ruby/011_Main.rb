# Cinder Crypt - main loop.

def cc_main
  Graphics.resize_screen(SW, SH)
  Graphics.frame_rate = 60
  load_save
  $G = CCGame.new
  $R = Renderer.new
  Snd.music(0)
  loop do
    Graphics.update
    Input.update
    $G.update(DT)
    $R.draw
  end
end

rgss_main { cc_main }
