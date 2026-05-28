extends Node

# Formats a float as a comma-separated integer string (no decimal places).
# Examples: 999 → "999", 1000 → "1,000", 1000000 → "1,000,000"
func format_number(value: float) -> String:
	var int_val: int = int(value)
	var s: String = str(abs(int_val))
	var length: int = s.length()
	var result: String = ""
	for i: int in length:
		if i > 0 and (length - i) % 3 == 0:
			result += ","
		result += s[i]
	if int_val < 0:
		result = "-" + result
	return result
