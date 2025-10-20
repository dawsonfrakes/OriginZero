import sys
from pathlib import Path

if __name__ == "__main__":
	path = Path(sys.argv[1])
	src = path.read_text()
	print(src)
