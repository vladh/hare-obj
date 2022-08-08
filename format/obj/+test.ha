use fmt;
use io;
use os;
use strconv;
use strings;

@test fn test() void = {
	const f = os::open("test.obj")!;
	const s = scan(f);

	let n_vertices = 0;
	let n_texcoords = 0;
	let n_normals = 0;
	let n_faces = 0;

	for (true) {
		const res = next(&s);
		if (res is io::EOF) {
			break;
		};
		let c = res as command;

		const (name, args) = c;
		switch (name) {
		case "v" =>
			let a = args: v4_command_args;
			n_vertices += 1;
			if (n_vertices == 1) {
				assert(a[0] == 1.0 &&
					a[1] == -1.0 &&
					a[2] == -1.0 &&
					a[3] == 1.0);
			};
		case "vt" =>
			let a = args: v2_command_args;
			n_texcoords += 1;
			if (n_texcoords == 1) {
				assert(a[0] == 1.0 && a[1] == 0.333333);
			};
		case "vn" =>
			let a = args: v4_command_args;
			n_normals += 1;
			if (n_normals == 1) {
				assert(a[0] == 0.0 &&
					a[1] == -1.0 &&
					a[2] == 0.0 &&
					a[3] == 1.0);
			};
		case "f" =>
			n_faces += 1;
			let a = args: face_command_args;
			assert(a.n_points == 3);
			assert(a.points[0].v > 0);
			assert(a.points[0].vt > 0);
			assert(a.points[0].vn > 0);
			assert(a.points[1].v > 0);
			assert(a.points[1].vt > 0);
			assert(a.points[1].vn > 0);
			assert(a.points[2].v > 0);
			assert(a.points[2].vt > 0);
			assert(a.points[2].vn > 0);
			if (n_faces == 1) {
				assert(a.points[1].v == 3 &&
					a.points[1].vt == 2 &&
					a.points[1].vn == 1);
			};
		case =>
			void;
		};
	};

	assert(n_vertices == 8);
	assert(n_texcoords == 14);
	assert(n_normals == 6);
	assert(n_faces == 12);

	defer finish(&s);
};

@test fn bunny() void = {
	const f = os::open("bunny.obj")!;
	const s = scan(f);

	let n_vertices = 0;
	let n_faces = 0;

	for (true) {
		const res = next(&s);
		if (res is io::EOF) {
			break;
		};
		let c = res as command;

		const (name, args) = c;
		switch (name) {
		case "v" =>
			n_vertices += 1;
		case "f" =>
			n_faces += 1;
		};
	};

	assert(n_vertices == 2503);
	assert(n_faces == 4968);

	defer finish(&s);
};
