// © 2022 Vlad-Stefan Harbuz <vlad@vladh.net>
// SPDX-License-Identifier: MIT

// Loosely based on hare-scfg, which contains the following copyright notice:
// License: MPL-2.0
// (c) 2022 Chris Palmer <chris@red-oxide.org>
// https://git.sr.ht/~chrisppy/hare-scfg

use bufio;
use encoding::utf8;
use fmt;
use io;
use os;
use shlex;
use strconv;
use strings;

export type v4_command_args = [4]f64;
export type v2_command_args = [2]f64;
export type face_point = struct {
	v: i64,
	vt: i64,
	vn: i64,
};
export type face_command_args = struct {
	points: [4]face_point,
	n_points: size,
};
export type invalid_command_args = !void;
export type command_args = (
	v4_command_args | v2_command_args | face_command_args |
	invalid_command_args
);
export type command_name = str;

export type scanner = struct {
	in: io::handle,
	lineno: uint,
	name: command_name,
	args: command_args,
};

// A command in an OBJ file, such as `v 1.0 -1.0 1.0`.
export type command = (const command_name, const command_args);

// A syntax error occured during parsing.
export type syntaxerr = !size;

// Any error which can occur during OBJ parsing.
export type error = !(io::error | syntaxerr | utf8::invalid | shlex::syntaxerr);

// Convert an [[error]] to a user-friendly string representation.
export fn strerror(err: error) const str = match (err) {
	case let s: syntaxerr =>
		static let buf: [1024]u8 = [0...];
		yield fmt::bsprintf(buf, "{} Invalid syntax", s: size);
	case shlex::syntaxerr =>
		yield "Syntax error";
	case utf8::invalid =>
		yield "Document is not valid UTF-8";
	case let err: io::error =>
		yield io::strerror(err);
};

// Creates an OBJ scanner. Use [[next]] to read commands. The caller must call
// [[finish]] once they're done with this object.
export fn scan(in: io::handle) scanner = scanner {
	in = in,
	...
};

// Scans and returns the next [[command]]. Unsupported commands will be
// completely ignored.
export fn next(
	s: *scanner
) (command | io::EOF | strconv::invalid | strconv::overflow | error) = {
	for (true) {
		s.lineno += 1;

		const line = match (bufio::scanline(s.in)?) {
		case let b: []u8 =>
			yield strings::try_fromutf8(b)?;
		case io::EOF =>
			return io::EOF;
		};

		const line = strings::trim(line);

		if (len(line) == 0 || strings::hasprefix(line, "#")) {
			continue;
		};

		const sline = shlex::split(line)?;
		defer strings::freeall(sline);

		s.args = []: v4_command_args;
		s.name = strings::dup(sline[0]);

		if (s.name == "v") {
			s.args = []: v4_command_args;
			(s.args as v4_command_args)[3] = 1.0;
			for (let i = 1z; i < len(sline); i += 1) {
				(s.args as v4_command_args)[i - 1] =
					strconv::stof64(sline[i])?;
			};
		} else if (s.name == "vt") {
			s.args = []: v2_command_args;
			for (let i = 1z; i < len(sline); i += 1) {
				(s.args as v2_command_args)[i - 1] =
					strconv::stof64(sline[i])?;
			};
		} else if (s.name == "vn") {
			s.args = []: v4_command_args;
			(s.args as v4_command_args)[3] = 1.0;
			for (let i = 1z; i < len(sline); i += 1) {
				(s.args as v4_command_args)[i - 1] =
					strconv::stof64(sline[i])?;
			};
		} else if (s.name == "f") {
			s.args = face_command_args { ... };
			(s.args as face_command_args).n_points = len(sline) - 1;
			for (let i = 1z; i < len(sline); i += 1) {
				const parts = strings::split(sline[i], "/");
				defer free(parts);
				(s.args as face_command_args).points[i - 1].v =
					strconv::stoi64(parts[0])?;
				if (len(parts) > 1) {
					(s.args as face_command_args).points[i - 1].vt =
						strconv::stoi64(parts[1])?;
				};
				if (len(parts) > 2) {
					(s.args as face_command_args).points[i - 1].vn =
						strconv::stoi64(parts[2])?;
				};
			};
		} else {
			s.args = void: invalid_command_args;
		};

		return (s.name, s.args);
	};
	abort(); // Unreachable
};

// Frees the resources associated with a [[scanner]].
export fn finish(s: *scanner) void = {
	free(s.name);
};
