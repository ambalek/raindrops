## Raindrops

![Image](raindrops.png)

### About

Norns generative script that makes melodies. Featuring 𝖑𝖔𝖋𝖎 𝖘𝖓𝖔𝖜𝖋𝖑𝖆𝖐𝖊𝖘. You can listen to it and try pressing the buttons or turning the knobs, but I found it works best if you sample something from it externally with a looper, then layer new melodies on top.

Sound example: [lofi-snowflakes on SoundCloud](https://soundcloud.com/ambalek/lofi-snowflakes)

### Controls

* Key 2: Randomize current scale
* Key 3: Stop and generate a new scale/melody
* Enc 1: Increase long buffer time, random chance of changing buffer speed
* Enc 2: Random pulse width value for melody, random 𝖑𝖔𝖋𝖎 𝖘𝖓𝖔𝖜𝖋𝖑𝖆𝖐𝖊𝖘 mode
* Enc 3: Change one of the notes randomly

### References

* I learned how to mix hiss and SuperCollider's Decimator output from [Otis](https://github.com/justmat/otis/blob/master/lib/Engine_Decimator.sc) -- I tried using the compressor to duck the hiss from Otis as well
* The sound source is copied from [PolyPerc](https://github.com/monome/dust/blob/master/lib/sc/Engine_PolyPerc.sc), extended with Decimator

### License

MIT
