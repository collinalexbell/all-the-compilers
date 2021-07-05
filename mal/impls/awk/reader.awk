function reader_read_string(token,    v, r)
{
	token = substr(token, 1, length(token) - 1)
	gsub(/\\\\/, "\xf7", token)
	gsub(/\\"/, "\"", token)
	gsub(/\\n/, "\n", token)
	gsub("\xf7", "\\", token)
	return token
}

function reader_read_atom(token)
{
	switch (token) {
	case "true":
	case "false":
	case "nil":
		return "#" token
	case /^:/:
		return ":" token
	case /^"/:
		if (token ~ /^\"(\\.|[^\\"])*\"$/) {
				return reader_read_string(token)
		} else {
				return "!\"Expected '\"', got EOF."
		}
	case /^-?[0-9]+$/:
		return "+" token
	default:
		return "'" token
	}
}

function reader_read_list(reader, type, end,    idx, len, ret)
{
	idx = types_allocate()
	len = 0
	while (reader["curidx"] in reader) {
		if (reader[reader["curidx"]] == end) {
			types_heap[idx]["len"] = len
			reader["curidx"]++
			return type idx
		}
		ret = reader_read_from(reader)
		if (ret ~ /^!/) {
			types_heap[idx]["len"] = len
			types_release(type idx)
			return ret
		}
		types_heap[idx][len++] = ret
	}
	types_heap[idx]["len"] = len
	types_release(type idx)
	return "!\"expected '" end "', got EOF"
}

function reader_read_hash(reader,    idx, key, val)
{
	idx = types_allocate()
	while (reader["curidx"] in reader) {
		if (reader[reader["curidx"]] == "}") {
			reader["curidx"]++
			return "{" idx
		}
		key = reader_read_from(reader)
		if (key ~ /^!/) {
			types_release("{" idx)
			return key
		}
		if (key !~ /^[":]/) {
			types_release(key)
			types_release("{" idx)
			return "!\"Hash-map key must be string or keyword."
		}
		if (!(reader["curidx"] in reader)) {
			types_release("{" idx)
			return "!\"Element count of hash-map must be even."
		}
		val = reader_read_from(reader)
		if (val ~ /^!/) {
			types_release("{" idx)
			return val
		}
		types_heap[idx][key] = val
	}
	types_release("{" idx)
	return "!\"expected '}', got EOF"
}

function reader_read_abbrev(reader, symbol,    val, idx)
{
	val = reader_read_from(reader)
	if (val ~ /^!/) {
		return val
	}
	idx = types_allocate()
	types_heap[idx]["len"] = 2
	types_heap[idx][0] = symbol
	types_heap[idx][1] = val
	return "(" idx
}

function reader_read_with_meta(reader,    meta, val, idx)
{
	meta = reader_read_from(reader)
	if (meta ~ /^!/) {
		return meta
	}
	val = reader_read_from(reader)
	if (val ~ /^!/) {
		types_release(meta)
		return val
	}
	idx = types_allocate()
	types_heap[idx]["len"] = 3
	types_heap[idx][0] = "'with-meta"
	types_heap[idx][1] = val
	types_heap[idx][2] = meta
	return "(" idx
}

function reader_read_from(reader,    current)
{
	current = reader[reader["curidx"]++]
	switch (current) {
	case "(":
		return reader_read_list(reader, "(", ")")
	case "[":
		return reader_read_list(reader, "[", "]")
	case "{":
		return reader_read_hash(reader)
	case ")":
	case "]":
	case "}":
		return "!\"Unexpected token '" current "'."
	case "'":
		return reader_read_abbrev(reader, "'quote")
	case "`":
		return reader_read_abbrev(reader, "'quasiquote")
	case "~":
		return reader_read_abbrev(reader, "'unquote")
	case "~@":
		return reader_read_abbrev(reader, "'splice-unquote")
	case "@":
		return reader_read_abbrev(reader, "'deref")
	case "^":
		return reader_read_with_meta(reader)
	default:
		return reader_read_atom(current)
	}
}

function reader_tokenizer(str,    reader,    len, r)
{
	for (len = 0; match(str, /^[ \t\r\n,]*(~@|[\[\]{}()'`~^@]|\"(\\.|[^\\"])*\"?|;[^\r\n]*|[^ \t\r\n\[\]{}('"`,;)^~@][^ \t\r\n\[\]{}('"`,;)]*)/, r); ) {
		if (substr(r[1], 1, 1) != ";") {
			reader[len++] = r[1]
		}
		str = substr(str, RSTART + RLENGTH)
	}
	if (str !~ /^[ \t\r\n,]*$/) {
		return "!\"Cannot tokenize '" str "'."
	}
	reader["len"] = len
	return ""
}

function reader_read_str(str,    reader, ret)
{
	ret = reader_tokenizer(str,    reader)
	if (ret != "") {
		return ret
	}
	if (reader["len"] == 0) {
		return "#nil"
	}
	ret = reader_read_from(reader)
	if (ret ~ /^!/) {
		return ret
	}
	if (reader["len"] != reader["curidx"]) {
		types_release(ret)
		return "!\"Unexpected token '" reader[reader["curidx"]] "'."
	}
	return ret
}
