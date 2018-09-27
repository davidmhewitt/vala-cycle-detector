/*
* Copyright (c) 2018 David Hewitt (https://github.com/davidmhewitt)
*
* This file is part of Vala Cycle Detector (VCD)
*
* VCD is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* VCD is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with VCD.  If not, see <http://www.gnu.org/licenses/>.
*/

class Vala.Compiler {
	private const string DEFAULT_COLORS = "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";

	static string basedir;
	static string directory;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] sources;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] vapi_directories;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] gir_directories;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] metadata_directories;
	static string vapi_filename;
	static string gir;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] packages;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] fast_vapis;
	static string target_glib;

	static bool ccode_only;
	static bool abi_stability;
	static string header_filename;
	static bool use_header;
	static string internal_header_filename;
	static string internal_vapi_filename;
	static string fast_vapi_filename;
	static bool vapi_comments;
	static string symbols_filename;
	static string includedir;
	static bool compile_only;
	static bool debug;
	static bool disable_assert;
	static bool enable_checking;
	static bool deprecated;
	static bool hide_internal;
	static bool disable_since_check;
	static bool disable_warnings;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] cc_options;
	static string pkg_config_command;
	static bool save_temps;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] defines;
	static bool quiet_mode;
	static bool verbose_mode;
	static string profile;
	static bool nostdpkg;
	static bool fatal_warnings;
	static bool disable_colored_output;
	static Report.Colored colored_output = Report.Colored.AUTO;
	static string dependencies;

	static string entry_point;

	static bool run_output;
	static string run_args;

	private CodeContext context;

	const OptionEntry[] options = {
		{ "vapidir", 0, 0, OptionArg.FILENAME_ARRAY, ref vapi_directories, "Look for package bindings in DIRECTORY", "DIRECTORY..." },
		{ "girdir", 0, 0, OptionArg.FILENAME_ARRAY, ref gir_directories, "Look for .gir files in DIRECTORY", "DIRECTORY..." },
		{ "metadatadir", 0, 0, OptionArg.FILENAME_ARRAY, ref metadata_directories, "Look for GIR .metadata files in DIRECTORY", "DIRECTORY..." },
		{ "pkg", 0, 0, OptionArg.STRING_ARRAY, ref packages, "Include binding for PACKAGE", "PACKAGE..." },
		{ "vapi", 0, 0, OptionArg.FILENAME, ref vapi_filename, "Output VAPI file name", "FILE" },
		{ "gir", 0, 0, OptionArg.STRING, ref gir, "GObject-Introspection repository file name", "NAME-VERSION.gir" },
		{ "basedir", 'b', 0, OptionArg.FILENAME, ref basedir, "Base source directory", "DIRECTORY" },
		{ "directory", 'd', 0, OptionArg.FILENAME, ref directory, "Change output directory from current working directory", "DIRECTORY" },
		{ "use-header", 0, 0, OptionArg.NONE, ref use_header, "Use C header file", null },
		{ "includedir", 0, 0, OptionArg.FILENAME, ref includedir, "Directory used to include the C header file", "DIRECTORY" },
		{ "internal-header", 'h', 0, OptionArg.FILENAME, ref internal_header_filename, "Output internal C header file", "FILE" },
		{ "internal-vapi", 0, 0, OptionArg.FILENAME, ref internal_vapi_filename, "Output vapi with internal api", "FILE" },
		{ "fast-vapi", 0, 0, OptionArg.STRING, ref fast_vapi_filename, "Output vapi without performing symbol resolution", null },
		{ "use-fast-vapi", 0, 0, OptionArg.STRING_ARRAY, ref fast_vapis, "Use --fast-vapi output during this compile", null },
		{ "vapi-comments", 0, 0, OptionArg.NONE, ref vapi_comments, "Include comments in generated vapi", null },
		{ "deps", 0, 0, OptionArg.STRING, ref dependencies, "Write make-style dependency information to this file", null },
		{ "symbols", 0, 0, OptionArg.FILENAME, ref symbols_filename, "Output symbols file", "FILE" },
		{ "define", 'D', 0, OptionArg.STRING_ARRAY, ref defines, "Define SYMBOL", "SYMBOL..." },
		{ "main", 0, 0, OptionArg.STRING, ref entry_point, "Use SYMBOL as entry point", "SYMBOL..." },
		{ "nostdpkg", 0, 0, OptionArg.NONE, ref nostdpkg, "Do not include standard packages", null },
		{ "disable-assert", 0, 0, OptionArg.NONE, ref disable_assert, "Disable assertions", null },
		{ "enable-checking", 0, 0, OptionArg.NONE, ref enable_checking, "Enable additional run-time checks", null },
		{ "enable-deprecated", 0, 0, OptionArg.NONE, ref deprecated, "Enable deprecated features", null },
		{ "hide-internal", 0, 0, OptionArg.NONE, ref hide_internal, "Hide symbols marked as internal", null },
		{ "disable-warnings", 0, 0, OptionArg.NONE, ref disable_warnings, "Disable warnings", null },
		{ "fatal-warnings", 0, 0, OptionArg.NONE, ref fatal_warnings, "Treat warnings as fatal", null },
		{ "disable-since-check", 0, 0, OptionArg.NONE, ref disable_since_check, "Do not check whether used symbols exist in local packages", null },
		{ "pkg-config", 0, 0, OptionArg.STRING, ref pkg_config_command, "Use COMMAND as pkg-config command", "COMMAND" },
		{ "profile", 0, 0, OptionArg.STRING, ref profile, "Use the given profile instead of the default", "PROFILE" },
		{ "quiet", 'q', 0, OptionArg.NONE, ref quiet_mode, "Do not print messages to the console", null },
		{ "verbose", 'v', 0, OptionArg.NONE, ref verbose_mode, "Print additional messages to the console", null },
		{ "no-color", 0, 0, OptionArg.NONE, ref disable_colored_output, "Disable colored output, alias for --color=never", null },
		{ "color", 0, OptionFlags.OPTIONAL_ARG, OptionArg.CALLBACK, (void*) option_parse_color, "Enable color output, options are 'always', 'never', or 'auto'", "WHEN" },
		{ "target-glib", 0, 0, OptionArg.STRING, ref target_glib, "Target version of glib for code generation", "MAJOR.MINOR" },
		{ "run-args", 0, 0, OptionArg.STRING, ref run_args, "Arguments passed to directly compiled executeable", null },
		{ "abi-stability", 0, 0, OptionArg.NONE, ref abi_stability, "Enable support for ABI stability", null },
		{ OPTION_REMAINING, 0, 0, OptionArg.FILENAME_ARRAY, ref sources, null, "FILE..." },
		{ null }
	};

	static bool option_parse_color (string option_name, string? val, void* data) throws OptionError {
		switch (val) {
			case "auto": colored_output = Report.Colored.AUTO; break;
			case "never": colored_output = Report.Colored.NEVER; break;
			case null:
			case "always": colored_output = Report.Colored.ALWAYS; break;
			default: throw new OptionError.FAILED ("Invalid --color argument '%s'", val);
		}
		return true;
	}

	private int quit () {
		if (context.report.get_errors () == 0 && context.report.get_warnings () == 0) {
			return 0;
		}
		if (context.report.get_errors () == 0 && (!fatal_warnings || context.report.get_warnings () == 0)) {
			if (!quiet_mode) {
				stdout.printf ("Compilation succeeded - %d warning(s)\n", context.report.get_warnings ());
			}
			return 0;
		} else {
			if (!quiet_mode) {
				stdout.printf ("Compilation failed: %d error(s), %d warning(s)\n", context.report.get_errors (), context.report.get_warnings ());
			}
			return 1;
		}
	}

	private int run () {
		context = new CodeContext ();
		CodeContext.push (context);

		if (disable_colored_output) {
			colored_output = Report.Colored.NEVER;
		}

		if (colored_output != Report.Colored.NEVER) {
			unowned string env_colors = Environment.get_variable ("VALA_COLORS");
			if (env_colors != null) {
				context.report.set_colors (env_colors, colored_output);
			} else {
				context.report.set_colors (DEFAULT_COLORS, colored_output);
			}
		}

		context.assert = !disable_assert;
		context.checking = enable_checking;
		context.deprecated = deprecated;
		context.since_check = !disable_since_check;
		context.hide_internal = hide_internal;
		context.report.enable_warnings = !disable_warnings;
		context.report.set_verbose_errors (!quiet_mode);
		context.verbose_mode = verbose_mode;

		context.ccode_only = ccode_only;
		if (ccode_only && cc_options != null) {
			Report.warning (null, "-X has no effect when -C or --ccode is set");
		}
		context.abi_stability = abi_stability;
		context.compile_only = compile_only;
		context.header_filename = header_filename;
		if (header_filename == null && use_header) {
			Report.error (null, "--use-header may only be used in combination with --header");
		}
		context.use_header = use_header;
		context.internal_header_filename = internal_header_filename;
		context.symbols_filename = symbols_filename;
		context.includedir = includedir;

		if (basedir == null) {
			context.basedir = CodeContext.realpath (".");
		} else {
			context.basedir = CodeContext.realpath (basedir);
		}
		if (directory != null) {
			context.directory = CodeContext.realpath (directory);
		} else {
			context.directory = context.basedir;
		}
		context.vapi_directories = vapi_directories;
		context.vapi_comments = vapi_comments;
		context.gir_directories = gir_directories;
		context.metadata_directories = metadata_directories;
		context.debug = debug;
		context.save_temps = save_temps;
		if (ccode_only && save_temps) {
			Report.warning (null, "--save-temps has no effect when -C or --ccode is set");
		}
		if (profile == "gobject-2.0" || profile == "gobject" || profile == null) {
			// default profile
			context.profile = Profile.GOBJECT;
			context.add_define ("GOBJECT");
		} else {
			Report.error (null, "Unknown profile %s".printf (profile));
		}
		nostdpkg |= fast_vapi_filename != null;
		context.nostdpkg = nostdpkg;

		context.entry_point_name = entry_point;

		context.run_output = run_output;

		if (pkg_config_command == null) {
			pkg_config_command = Environment.get_variable ("PKG_CONFIG") ?? "pkg-config";
		}
		context.pkg_config_command = pkg_config_command;

		if (defines != null) {
			foreach (string define in defines) {
				context.add_define (define);
			}
		}

		for (int i = 2; i <= 42; i += 2) {
			context.add_define ("VALA_0_%d".printf (i));
		}

		int glib_major = 2;
		int glib_minor = 40;
		if (target_glib != null && target_glib.scanf ("%d.%d", out glib_major, out glib_minor) != 2) {
			Report.error (null, "Invalid format for --target-glib");
		}

		context.target_glib_major = glib_major;
		context.target_glib_minor = glib_minor;
		if (context.target_glib_major != 2) {
			Report.error (null, "This version of valac only supports GLib 2");
		}

		for (int i = 16; i <= glib_minor; i += 2) {
			context.add_define ("GLIB_2_%d".printf (i));
		}

		if (!nostdpkg) {
			/* default packages */
			context.add_external_package ("glib-2.0");
			context.add_external_package ("gobject-2.0");
		}

		if (packages != null) {
			foreach (string package in packages) {
				context.add_external_package (package);
			}
			packages = null;
		}

		if (fast_vapis != null) {
			foreach (string vapi in fast_vapis) {
				var rpath = CodeContext.realpath (vapi);
				var source_file = new SourceFile (context, SourceFileType.FAST, rpath);
				context.add_source_file (source_file);
			}
			context.use_fast_vapi = true;
		}

		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

		bool has_c_files = false;
		bool has_h_files = false;

		foreach (string source in sources) {
			if (context.add_source_filename (source, run_output, true)) {
				if (source.has_suffix (".c")) {
					has_c_files = true;
				} else if (source.has_suffix (".h")) {
					has_h_files = true;
				}
			}
		}
		sources = null;
		if (ccode_only && (has_c_files || has_h_files)) {
			Report.warning (null, "C header and source files are ignored when -C or --ccode is set");
		}

		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

		var parser = new Parser ();
		parser.parse (context);

		var genie_parser = new Genie.Parser ();
		genie_parser.parse (context);

		var gir_parser = new GirParser ();
		gir_parser.parse (context);

		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

		context.check ();

        var graph_builder = new GraphBuilder (context);

		if (context.report.get_errors () > 0 || (fatal_warnings && context.report.get_warnings () > 0)) {
			return quit ();
		}

		if (!ccode_only && !compile_only) {
			// building program, require entry point
			if (!has_c_files && context.entry_point == null) {
				Report.error (null, "program does not contain a static `main' method");
			}
		}

		return quit ();
	}

	static int main (string[] args) {
		// initialize locale
		Intl.setlocale (LocaleCategory.ALL, "");

		try {
			var opt_context = new OptionContext ("- Vala Compiler");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			opt_context.parse (ref args);
		} catch (OptionError e) {
			stdout.printf ("%s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return 1;
		}

		if (sources == null && fast_vapis == null) {
			stderr.printf ("No source file specified.\n");
			return 1;
		}

		var compiler = new Compiler ();
		return compiler.run ();
	}
}
