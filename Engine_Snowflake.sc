// Based on: https://github.com/monome/dust/blob/master/lib/sc/Engine_PolyPerc.sc
Engine_Snowflake : CroneEngine {
  var pg;
  var amp = 0.3;
  var release = 0.5;
  var pan = 0.5;
  var pw = 0.5;
  var cutoff = 1000;
  var gain = 1;
  var bits = 32;
  var hiss = 0;
  var sampleRate = 48000.0;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    pg = ParGroup.tail(context.xg);
    SynthDef("Snowflake", {
      arg out, freq = 440, pw = pw, amp = amp, cutoff = cutoff, gain = gain, release = release, bits = bits, hiss = hiss;
      var snd = Pulse.ar(freq, pw);
      var filt = MoogFF.ar(snd, cutoff, gain);
      var env = Env.perc(level: amp, releaseTime: release).kr(2);
      var decimate = Decimator.ar(filt * env, rate: sampleRate, bits: bits, mul: 1.0, add: 0);
      var hissMix = HPF.ar(Mix.new([PinkNoise.ar(1), Dust.ar(5,1)]), 2000, 1);
      var duckedHiss = Compander.ar(hissMix, decimate,
        thresh: 0.4,
        slopeBelow: 1,
        slopeAbove: 0.2,
        clampTime: 0.01,
        relaxTime: 0.1,
      ) * (hiss / 500);
      Out.ar(out, Mix.new([decimate, duckedHiss]));
    }).add;

    this.addCommand("hz", "f", { arg msg;
      var val = msg[1];
      Synth("Snowflake",
        [
          \out, context.out_b,
          \freq, val,
          \pw, pw,
          \amp, amp,
          \cutoff, cutoff,
          \gain, gain,
          \release, release,
          \pan, pan,
          \bits, bits,
          \hiss, hiss
        ],
        target: pg
      );
    });
    this.addCommand("hiss", "i", { arg msg;
      hiss = msg[1];
    });
    this.addCommand("bits", "i", { arg msg;
      bits = msg[1];
    });
    this.addCommand("pan", "f", { arg msg;
      pan = msg[1];
    });
    this.addCommand("amp", "f", { arg msg;
      amp = msg[1];
    });
    this.addCommand("pw", "f", { arg msg;
      pw = msg[1];
    });
    this.addCommand("release", "f", { arg msg;
      release = msg[1];
    });
    this.addCommand("cutoff", "f", { arg msg;
      cutoff = msg[1];
    });
    this.addCommand("gain", "f", { arg msg;
      gain = msg[1];
    });
  }
}