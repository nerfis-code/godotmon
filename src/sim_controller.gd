class_name SimController
extends RefCounted

var pipe: FileAccess
var pid: int
var thread: Thread
var _callback: Callable

func _init(callback: Callable) -> void:
	_callback = callback
	var process_info := OS.execute_with_pipe("node", ["sim/index.js"])
	
	if process_info.is_empty():
		print("Error: No se pudo iniciar Node.js. Verifica tu instalación.")
		return
		
	pipe = process_info["stdio"]
	pid = process_info["pid"]
	
	thread = Thread.new()
	thread.start(_read_pipe_loop)

func _read_pipe_loop():
	while pipe.get_error() == OK and not pipe.eof_reached():
		var linea = pipe.get_line()
		if linea != "":
			call_deferred("_on_message_received", linea)

func _on_message_received(message: String):
	_callback.call(message)

func _dispose():
	if pid > 0:
		OS.kill(pid)
	if thread and thread.is_started():
		thread.wait_to_finish()

func push_command(command: String):
	if pipe:
		pipe.store_line(command)
		pipe.flush()

func _on_move_pressed(extra_arg_0: int) -> void:
	push_command("move " + str(extra_arg_0))

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_dispose()
