class_name TextRunner
extends Node

static var error_queue: Array
static var visited: Array
var test_suites = {"failed": 0, "passed": 0, "total": 0}
var tests = {"failed": 0, "passed": 0, "total": 0 }
var snapshots = 0
var time = 0

func _ready() -> void:
	var start_time = Time.get_ticks_msec()
	
	var test_files = _find_test_files("test")
	for test_file in test_files:
		run(test_file)
	
	var end_time = Time.get_ticks_msec()
	time = (end_time - start_time) / 1000
	
	print("\n\n")
	print("Test Suites: %d failed, %d passed, %d total" % [test_suites.failed, test_suites.passed, test_suites.total])
	print("Tests: %d failed, %d passed, %d total" % [tests.failed, tests.passed, tests.total])
	print("Snapshots: 0 total")
	print("Time: %d s" % time)
	print("Ran all test suites.")
	get_tree().quit()

func run(script_path: String) -> void:
	var file = FileAccess.open("res://" + script_path, FileAccess.READ)
	var content = file.get_as_text()
	var execs = []

	var fn_regex = RegEx.create_from_string("func \\w+\\(\\).*?:")

	for match in fn_regex.search_all(content):
		var fn_declaration = match.get_string()
		var body_regex = RegEx.create_from_string("[\\s\\S]*?(?=func\\s+\\w|$)")
		
		var fn_line = content.substr(0, match.get_end()).count("\n") + 1
		var body = body_regex.search(content, match.get_end()).get_string()
		var fn_name = fn_declaration.get_slice(" ", 1).get_slice("(", 0)
		

		var script = load("res://" + script_path).new()
		var exec = {
			name = fn_name,
			all_right = true,
		}
		execs.push_back(exec)

		script.call(fn_name)
		if not error_queue.is_empty():
			var error = error_queue.pop_front()
			exec.all_right = false
			exec.pos = Vector2i()
			var lines = body.split("\n")
			var i = 0
			var ignore_count = error.count

			for line in lines:
				var j = line.find(error.fn + "(")
				if j != -1:
					if ignore_count > 0:
						ignore_count -= 1
					else:
						var new_line = "^".lpad(j)
						lines.insert(i + 1, "".lpad(line.count("\t"), "\t") + new_line)
						exec.pos.x = j
						break

				i += 1
			
			exec.error_line = lines[i]
			
			var fn_line_max_width = str(fn_line + lines.size() - 1).length()
			var ignore = 0
			for j in range(lines.size()):
				lines[j] = lines[j].replace("\t", "    ")
				if j == i:
					exec.pos.y = fn_line + 1 + j
					lines[j] = "> %*d|  " % [fn_line_max_width, fn_line + 1 + j] + lines[j]
				elif j == i + 1:
					lines[j] = "  %*s  " % [fn_line_max_width + 1, " |"] + lines[j]
					ignore = -1
				else:
					lines[j] = "  %*d|  " % [fn_line_max_width, fn_line + 1 + j + ignore] + lines[j]

			exec.error_trace = "  %*d|  " % [fn_line_max_width, fn_line] + fn_declaration + "\n" + "\n".join(lines)
			exec.error = error
			exec.at = "\n  at Object.%s (%s:%d:%d)" % [error.fn, script_path, exec.pos.y, exec.pos.x]

	if execs.all(func(ex): return ex.all_right):
		print_rich("\n[bgcolor=green][color=white] PASS [/color][/bgcolor] " + script_path)
		test_suites.passed += 1
	else:
		print_rich("\n[bgcolor=red][color=white] FAIL [/color][/bgcolor] " + script_path)
		test_suites.failed += 1
	test_suites.total += 1

	for ex in execs:
		if ex.all_right:
			print("  ✓ " + ex.name)
			tests.passed += 1
		else:
			print("  ✕ " + ex.name)
			tests.failed += 1
		tests.total += 1

	for ex in execs:
		if ex.all_right:
			continue
		
		print("\n  ● " + ex.name)
		print("\n  " + ex.error_line)
		print("\n  Expected: " + str(ex.error.expected))
		print("  Received: " + str(ex.error.received))

		print("\n" + ex.error_trace)
		print(ex.at)

func _find_test_files(directory: String) -> Array:
	var test_files = []
	var dir = DirAccess.open("res://" + directory)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.begins_with("."):
				file_name = dir.get_next()
				continue
			
			var full_path = directory + "/" + file_name
			if dir.current_is_dir():
				test_files.append_array(_find_test_files(full_path))
			elif file_name.ends_with(".test.gd"):
				test_files.append(full_path)
			
			file_name = dir.get_next()
	
	return test_files
