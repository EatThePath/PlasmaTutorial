# Context on Plasma Core
 I've been working on various FSO lua projects for years now, I've included scripts in my mods that may go unnoticed but are vital to our gameplay, and am working on more. While working on them I've gotten more and more frustrated with haivng to reload the game every time I need to test a change. My focus is often fragile enough that even a 15 second reload can be a big problem for me and mod startups can take quite a bit longer than that.

In 2022 I noticed some ideas on a possibly better way, interactive development. It's something with a long history in some programming languages but I'd managed to largely miss out on before then. After many weekends of working and a few engine patches I finally got to try it in FSO, and fell in love immediately. 

In practical terms interactive development means that you can edit your code, or run one-off snippets, without ever restarting completely. It opens a very iterative process of using a simple sandbox level to test pieces of an idea immediately as you write them, discover and fix issues if needed and, repeat without ever restarting the engine or even level. For me it means finding errors faster, and having much less friction to trying out ideas. It's helped me make much better use of the time whenever I've sat down to work on a script project.

That process is what I hope will most come through my tutorials, so at least initiall I'm going to be focusing on the workflow, the steps I take in reaching a solution, rather than presenting perfected code at all times.

## Tools

The tools used here are hosted on [the FSO scripters repository<https://github.com/FSO-Scripters/fso-scripts>. They are: 
[Plasma Core](https://github.com/FSO-Scripters/fso-scripts/tree/master/plasma_core) and [(PCM) Codekeys](https://github.com/FSO-Scripters/fso-scripts/tree/master/pcm_codekeys)

Plasma Core is a framework that faciliates live reloading of scripts. To make that play nice with how scripts attach to the gameplay loop Plasma Core works with script modules it expects to be structured in a certain way. I'll explaing the parts of it we need as they come up, documentation of it's full capabilities and usage is available in the [Plasma Core readme file](https://github.com/FSO-Scripters/fso-scripts/blob/master/plasma_core/Readme.md) if you want to go beyond what's shown here.

Codekeys is a Plasma Core Module. While Plasma Core enables script reloading, it does not provide any direct way to activate it. Codekeys will do that for us, it attaches lua code to keyboard keys and execute them any time you press that key in game. Codekeys can be given new code to run at any time, but we'll typically only need the default configuration included in it: 9 to reload all scripts, and 0 to clear the fs2_open.log.

## FSO Setup

### Flags

On the FSO side there's a few launch flags that make this process go smoothly:

* -luadev: this makes many lua errors that would be fatal or popups into just log prints. This is vital to getting the real juicy benefits of interactive development.
* -output_scripting: Generally the most up to date source of scripting documentation, the engine writes a scripting.html when run with this flag.
* -window: fairly self-explantory why this might be useful when flipping back and forth between code and gameplay.
* -no_unfocused_pause: lets the game keep running when you tab out. With the correct testing mission this smooths out some bumps in the development experince
* -pilot [yourpilotname] and -start_mission [yourmissionname]: sometimes you'll still crash the game. These will let you get back to work afterwards asap.
* -debug_window: I personally use Microsoft Visual Studio Code with the fs2_open.log file open in a tab. This reloads fairly prompty when the file changes, and that
* -noninteractive: kind of a dangerous one, this means warnings and errosr don't have popups. Useful if you're keeping a close eye on the log, because the error notice sound drives me batty, but try not to leave it on all the time like I do.

If you're using Knossos you can put all these in the custom flags field, but most of them are in it's flags menu and you'll need to find them in it to turn them off later.

Finally, I use a debug filter file. This is a file named `debug_filter.cfg`, in `C:\Users\[username]\AppData\Roaming\HardLightProductions\FreeSpaceOpen\data\debug_filter.cfg` for windows users. My file for script development looks like this:

```
+error
+warning
-general
+scripting
```

If you can tolerate all the routine logging from FSO you don't have to use this, and if you do use this you should take it back off when you're done scripting, otherwise the next time something non-scripting breaks on you your log won't be very useful. But as I said before my focus is very fragile and for me getting rid of the all the text I don't need is a help. Sometimes I even turn off error and warning.

But again, turn the normal filters back on or remove the filter file entirely, and remove -noninteractive, when you're done or you'll be prone to not having any information the next time something you try in a mod doesn't work.