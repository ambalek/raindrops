-- luacheck: globals engine clock util screen softcut enc key audio init
-- 𝔯𝔞𝔦𝔫𝔡𝔯𝔬𝔭𝔰
local MusicUtil = require "musicutil"

local loop_end = 10
local max_loop_length = 50
local delay_end = 1

engine.name = 'PolyPerc'

local rates_index = 4
local rates = { 0.5, 1.0, 2.0, -0.5, -1.0, -2.0 }
local screen_width = 128
local screen_height = 64
local longest_note = 16
local highest_pitch = 1
local sequencer1 = nil
local sequencer2 = nil
local scales = { "Minor Pentatonic", "Major Pentatonic", "Mixolydian", "Phrygian" }
local played_notes = { {}, {} }
local scale_options = nil
local lfo_period = 240
local max_lfo_period  = 2400
local max_high_notes = 4
local anim_state = {
  change_one = {
    active = false,
    size = 0,
    speed = 0.5
  },
  delay_speed = {
    active = false,
    size = 0,
    speed = 0.5
  }
}

local function softcut_setup()
  softcut.reset()

  audio.level_cut(1.0)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  softcut.level(1, 0.65)
  softcut.level_slew_time(1, 0)
  softcut.level_input_cut(1, 1, 1.0)
  softcut.level_input_cut(2, 1, 1.0)
  softcut.pan(1, 0.0)
  softcut.play(1, 1)
  softcut.rate(1, rates[rates_index])
  softcut.rate_slew_time(1, 0)
  softcut.loop_start(1, 0)
  softcut.loop_end(1, loop_end)
  softcut.loop(1, 1)
  softcut.fade_time(1, 0.1)
  softcut.rec(1, 1)
  softcut.rec_level(1, 1)
  softcut.pre_level(1, 0.5)
  softcut.position(1, 0)
  softcut.enable(1, 1)
  softcut.filter_dry(1, 0)
  softcut.filter_lp(1, 1.0)
  softcut.filter_bp(1, 1.0)
  softcut.filter_hp(1, 1.0)
  softcut.filter_fc(1, 900)
  softcut.filter_rq(1, 2.0)

  softcut.level(2, 0.6)
  softcut.level_slew_time(2, 0)
  softcut.level_input_cut(1, 2, 1.0)
  softcut.level_input_cut(2, 2, 1.0)
  softcut.pan(2, 0.0)
  softcut.play(2, 1)
  softcut.rate(2, 1.0)
  softcut.rate_slew_time(2, 0)
  softcut.loop_start(2, 0)
  softcut.loop_end(2, delay_end)
  softcut.loop(2, 1)
  softcut.fade_time(2, 0.05)
  softcut.rec(2, 1)
  softcut.rec_level(2, 1)
  softcut.pre_level(2, 0.5)
  softcut.position(2, 0)
  softcut.enable(2, 1)
  softcut.filter_dry(2, 0)
  softcut.filter_lp(2, 1.0)
  softcut.filter_bp(2, 1.0)
  softcut.filter_hp(2, 1.0)
  softcut.filter_fc(2, 1200)
  softcut.filter_rq(2, 2.0)
end
local function change_one_note_animation()
  clock.run(
    function()
      anim_state.change_one.size = 50
      anim_state.change_one.level = 6
      anim_state.change_one.x = 50 + math.random(1, 10)
      anim_state.change_one.y = 40 + math.random(1, 10)
      anim_state.change_one.active = true
      while anim_state.change_one.size > 0 do
        anim_state.change_one.size = anim_state.change_one.size - anim_state.change_one.speed
        anim_state.change_one.level = util.clamp(anim_state.change_one.level - anim_state.change_one.speed, 1, 15)
        clock.sleep(1 / 30)
      end
      anim_state.change_one.active = false
    end
  )
end

local function change_delay_speed_animation()
  clock.run(
    function()
      anim_state.delay_speed.size = 80
      anim_state.delay_speed.level = 6
      anim_state.delay_speed.x = 50 + math.random(1, 10)
      anim_state.delay_speed.y = 40 + math.random(1, 10)
      anim_state.delay_speed.active = true
      while anim_state.delay_speed.size > 0 do
        anim_state.delay_speed.size = anim_state.delay_speed.size - anim_state.delay_speed.speed
        anim_state.delay_speed.level = util.clamp(anim_state.delay_speed.level - anim_state.delay_speed.speed, 1, 15)
        clock.sleep(1 / 30)
      end
      anim_state.delay_speed.active = false
    end
  )
end

local function make_scale_options()
  local random_scale = scales[math.random(1, #scales)]
  local start_note = math.random(44, 68)
  return {
    MusicUtil.generate_scale(start_note, random_scale, 3),
    MusicUtil.generate_scale(start_note - 12, random_scale, 2)
  }
end

local function generate_sequences()
  highest_pitch = 1
  local scale1 = scale_options[1]
  local scale2 = scale_options[2]
  return {
    {
      { hz = MusicUtil.note_num_to_freq(scale1[math.random(1, #scale1 - max_high_notes)]), length = math.random(2, 8) },
      { hz = MusicUtil.note_num_to_freq(scale1[math.random(1, #scale1 - max_high_notes)]), length = math.random(2, 4) },
      { hz = MusicUtil.note_num_to_freq(scale1[math.random(1, #scale1 - max_high_notes)]), length = math.random(1, 6) },
      { hz = MusicUtil.note_num_to_freq(scale1[math.random(1, #scale1 - max_high_notes)]), length = math.random(2, 6) },
      { hz = MusicUtil.note_num_to_freq(scale1[math.random(1, #scale1 - max_high_notes)]), length = math.random(1, 4) },
      { hz = MusicUtil.note_num_to_freq(scale1[math.random(1, #scale1 - max_high_notes)]), length = math.random(1, 4) },
      { hz = MusicUtil.note_num_to_freq(scale1[math.random(1, #scale1 - max_high_notes)]), length = math.random(1, 8) },
    },
    {
      { hz = MusicUtil.note_num_to_freq(scale2[math.random(1, #scale2)]), length = math.random(2, 4) },
      { hz = MusicUtil.note_num_to_freq(scale2[math.random(1, #scale2)]), length = math.random(2, 6) },
      { hz = MusicUtil.note_num_to_freq(scale2[math.random(1, #scale2)]), length = math.random(1, 6) },
      { hz = MusicUtil.note_num_to_freq(scale2[math.random(1, #scale2)]), length = math.random(2, 4) },
      { hz = MusicUtil.note_num_to_freq(scale2[math.random(1, #scale2)]), length = math.random(1, 6) },
      { hz = MusicUtil.note_num_to_freq(scale2[math.random(1, #scale2)]), length = math.random(2, 6) },
      { hz = MusicUtil.note_num_to_freq(scale2[math.random(1, #scale2)]), length = math.random(4, 6) },
    },
  }
end

local function make_sequence()
  scale_options = make_scale_options()
  return generate_sequences()
end

local sequence = make_sequence()

local function change_one_note()
  local seq = sequence[1]
  local scale1 = scale_options[1]
  seq[math.random(1, #seq)].hz = MusicUtil.note_num_to_freq(
    scale1[math.random(1, #scale1 - max_high_notes)]
  )
end

local function played_note(d, i, hz, length)
  if played_notes[d][i] == nil then
    played_notes[d][i] = { hz = hz, length = length }
  else
    played_notes[d][i].hz = hz
    played_notes[d][i].length = length
  end
  played_notes[d][i].x = nil
  if hz > highest_pitch then highest_pitch = hz end
end

local function tick(d, i, s)
  return function()
    local notes = sequence[d]
    for j = 1, #notes do
      notes[j].ticks = notes[j].length
    end
    while true do
      local note = notes[i]
      clock.sync(s)
      note.ticks = note.ticks - 1
      if note.ticks == 0 then
        engine.pan(math.random())
        engine.release(note.length)
        engine.hz(note.hz)
        note.ticks = note.length
        played_note(d, i, note.hz, note.length)
        i = i + 1
        if i > #notes then
          i = 1
        end
      end
    end
  end
end

local function length_to_level(length)
  local min = 3
  local max = 15
  return math.floor(((length / longest_note) * (max - min)) + 0.5) + min
end

local function hz_to_width(hz)
  local min = 1
  local max = 4
  return math.floor(((hz / highest_pitch) * (max - min)) + 0.5)
end

local function redraw()
  screen.clear()
  local margin = 30
  if anim_state.change_one.active then
    screen.level(math.floor(anim_state.change_one.level + 0.5))
    screen.circle(anim_state.change_one.x, anim_state.change_one.y, anim_state.change_one.size)
    screen.fill()
    screen.close()
  end
  if anim_state.delay_speed.active then
    screen.font_face(5)
    screen.font_size(anim_state.delay_speed.size)
    screen.move(anim_state.delay_speed.x, anim_state.delay_speed.y)
    screen.level(math.floor(anim_state.delay_speed.level + 0.5))
    screen.text("*")
    screen.fill()
    screen.close()
  end
  for i = 1, #played_notes do
    for j = 1, #played_notes[i] do
      local note = played_notes[i][j]
      if note ~= nil then
        if note.x == nil then
          note.x = math.floor(margin + math.random() * (screen_width)) - margin
          note.y = math.floor(margin + math.random() * (screen_height)) - margin
        end
        screen.line_width(hz_to_width(note.hz))
        screen.level(length_to_level(note.length))
        screen.circle(note.x, note.y, note.hz / 25)
        screen.stroke()
        screen.close()
        note.length = note.length - 0.01
      end
    end
  end
  screen.update()
end

local function reset_sequencers()
  played_notes = { {}, {} }
  clock.cancel(sequencer1)
  clock.cancel(sequencer2)
  sequencer1 = clock.run(tick(1, 1, 1))
  sequencer2 = clock.run(tick(2, 4, math.random(2, 5)))
end

function key(n, z)
  if n == 3 and z == 1 then
    softcut_setup()
    sequence = make_sequence()
    reset_sequencers()
  elseif n == 2 and z == 1 then
    sequence = generate_sequences()
    reset_sequencers()
  end
end

local function change_delay_speed(d)
  loop_end = util.clamp(loop_end + d, 1, max_loop_length)
  softcut.loop_end(1, loop_end)
  softcut.rec(1, 0)
  rates_index = util.wrap(rates_index + d, 1, #rates)
  softcut.rate(1, rates[rates_index])
  softcut.rec(1, 0)
end

function enc(n, d)
  if n == 1 then
    if math.random() > 0.7 and anim_state.delay_speed.active == false then
      change_delay_speed_animation()
      change_delay_speed(d)
    end
  elseif n == 2 then
    lfo_period = util.wrap(lfo_period + d, 10, max_lfo_period)
    engine.pw(math.random())
  elseif n == 3 then
    local scale1 = scale_options[1]
    max_high_notes = util.wrap(max_high_notes + d, 0, math.floor(#scale1 / 3))
    if math.random() > 0.7 and anim_state.change_one.active == false then
      change_one_note_animation()
      change_one_note()
    end
  end
end

local function screen_setup()
  screen.aa(1)
end

function init()
  screen_setup()
  softcut_setup()

  clock.run(
    function()
      while true do
        clock.sleep(1 / 30)
        redraw()
      end
    end
  )

  clock.run(
    function()
      while true do
        for i = 1, #played_notes do
          for j = 1, #played_notes[i] do
            local note = played_notes[i][j]
            if note ~= nil then
              note.hz = note.hz - 4
            end
          end
        end
        clock.sleep(0.1)
      end
    end
  )

  clock.run(
    function()
      local pan_time = 0
      while true do
        pan_time = util.wrap(pan_time + 1, 0, lfo_period)
        local pan = math.sin(2 * math.pi * pan_time / lfo_period)
        softcut.pan(1, pan)
        clock.sleep(0.1)
      end
    end
  )

  clock.run(
    function()
      while true do
        engine.cutoff(500)
        clock.sleep(10)
      end
    end
  )

  sequencer1 = clock.run(tick(1, 1, 1))
  sequencer2 = clock.run(tick(2, 4, math.random(2, 5)))
end