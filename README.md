# vala-cycle-detector

## Usage
Use the compiled binary with similar flags to what you'd pass to `valac` on the command line. Include `--define` arguments, `--pkg` arguments and all of your source files.

e.g.
`vala-cycle-detector --define=HAVE_UNITY --pkg unity --pkg json-glib-1.0 --pkg libsoup-2.4 --pkg appstream --pkg packagekit-glib2 --pkg granite --pkg gtk+-3.0 --pkg gee-0.8 --define=CURATED --define=SHARING ../src/Application.vala ../src/MainWindow.vala ../src/Settings.vala .....`

Copy the output not including any of the compilation warnings, it should look something like:
```
digraph code {
        graph [bb="0,0,20991,684"];
        node [label="\N"];
        "GLib.DBusObjectManagerClient"   [height=0.5,
                pos="9759.7,234",
                width=3.5566];
        string   [height=0.5,
                pos="9818.7,162",
                width=0.84854];
......
}
```

This can be pasted into something like Webgraphviz (http://webgraphviz.com/) to get a visual representation of what references what in your vala code.

Save the digraph into a file and then run 
