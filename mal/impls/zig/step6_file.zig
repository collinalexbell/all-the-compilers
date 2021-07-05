const std = @import("std");
const warn = @import("std").debug.warn;

const reader = @import("reader.zig");
const pcre = reader.pcre;
const printer = @import("printer.zig");
const getline = @import("readline.zig").getline;
const string_eql = @import("utils.zig").string_eql;
const string_copy = @import("utils.zig").string_copy;
const string_concat = @import("utils.zig").string_concat;
const apply_function = @import("types.zig").apply_function;
const linked_list = @import("linked_list.zig");
const hash_map = @import("hmap.zig");
const core = @import("core.zig");

const Allocator = @import("std").heap.c_allocator;

const MalType = @import("types.zig").MalType;
const MalTypeValue = @import("types.zig").MalTypeValue;
const MalData = @import("types.zig").MalData;
const MalError = @import("error.zig").MalError;
const MalFuncData = @import("types.zig").MalFuncData;
const MalLinkedList = @import("linked_list.zig").MalLinkedList;
const Env = @import("env.zig").Env;

var repl_environment: *Env = undefined;

fn READ(a: []const u8) MalError!?*MalType {
    var read = try reader.read_str(a);
    var optional_mal = reader.read_form(&read);
    return optional_mal;
}

fn EVAL(mal_arg: *MalType, env_arg: *Env) MalError!*MalType {
    var mal = mal_arg;
    var env = env_arg;
    while(true) {
        switch(mal.data) {
            .List => |ll| {
                if(ll.len == 0) {
                    return mal;
                }
                var first_mal = linked_list.first(&ll) orelse return MalError.ArgError;
                var symbol = switch(first_mal.data) {
                    .Generic => |symbol| symbol,
                    else => "",
                };
                if(string_eql(symbol, "def!")) {
                    return EVAL_def(mal, env);
                }
                else if(string_eql(symbol, "let*")) {
                    try EVAL_let(&mal, &env);
                    continue;
                }
                else if(string_eql(symbol, "do")) {
                    try EVAL_do(&mal, &env);
                    continue;
                }
                else if(string_eql(symbol, "if")) {
                    try EVAL_if(&mal, &env);
                    continue;
                }
                else if(string_eql(symbol, "fn*")) {
                    return EVAL_fn(mal, env);
                }
                else {
                    var new_list = try eval_ast(mal, try env.copy(Allocator));

                    if(MalTypeValue((try new_list.sequence_nth(0)).data) == MalTypeValue.Func) {
                        try do_user_func(try new_list.sequence_linked_list(), &mal, &env);
                        new_list.shallow_destroy(Allocator);
                        continue;
                    }
                    const res = try apply_function(Allocator, (try new_list.sequence_linked_list()).*);
                    new_list.delete(Allocator);
                    env.delete();
                    return res;
                }
            },
            else => {
                return eval_ast(mal, env);
            },
        }
    }
}

fn eval(a1: *MalType) MalError!*MalType {
    return EVAL(try a1.copy(Allocator), try repl_environment.copy(Allocator));
}

fn EVAL_def(mal: *MalType, env: *Env) MalError!*MalType {
    const first_arg = try mal.sequence_nth(1);
    const second_arg = try mal.sequence_nth(2);
    const second_arg_copy = try second_arg.copy(Allocator);
    const symbol_name = try first_arg.as_symbol();
    const new_value = try EVAL(second_arg_copy, try env.copy(Allocator));
    try env.set(symbol_name, new_value);
    mal.delete(Allocator);
    env.delete();
    return new_value.copy(Allocator);
}

fn EVAL_let(mal_ptr: **MalType, env_ptr: **Env) MalError!void {
    //TODO: make faster
    const mal = mal_ptr.*;
    const env = env_ptr.*;
    (try mal.sequence_pop_first(Allocator)).delete(Allocator);
    const binding_arg = try mal.sequence_pop_first(Allocator);
    const eval_arg = try mal.sequence_pop_first(Allocator);
    const new_env = try Env.new(Allocator, env);
    var binding_ll = switch(binding_arg.data) {
        .List => |l| l,
        .Vector => |v| v,
        else => return MalError.TypeError,
    };
    var iterator = binding_ll.iterator();
    var optional_node = iterator.next();
    while(optional_node) |node| {
        const key_mal = node;
        const key = try key_mal.as_symbol();
        const val_mal = iterator.next() orelse return MalError.ArgError;
        const evaled_mal = try EVAL(val_mal, try new_env.copy(Allocator));
        try new_env.set(key, evaled_mal);
        optional_node = iterator.next();
        key_mal.delete(Allocator);
    }
    
    linked_list.destroy(Allocator, &binding_ll, true);
    binding_arg.data = MalData{.Nil=undefined};
    binding_arg.delete(Allocator);
    mal.delete(Allocator);

    // We use eval_arg_copy, since we just deleted eval_arg above
    mal_ptr.* = eval_arg;
    env.delete();
    env_ptr.* = new_env;
}

fn EVAL_do(mal_ptr: **MalType, env_ptr: **Env) MalError!void {
    var mal = mal_ptr.*;
    var env = env_ptr.*;
    var ll = &mal.data.List;
    (try mal.sequence_pop_first(Allocator)).delete(Allocator);
    var last_mal = try mal.sequence_pop_last(Allocator);
    var evaled_mal = try eval_ast(mal, try env.copy(Allocator));
    evaled_mal.delete(Allocator);
    mal_ptr.* = last_mal;
}

fn EVAL_if(mal_ptr: **MalType, env_ptr: **Env) MalError!void {
    var mal = mal_ptr.*;
    var env = env_ptr.*;
    defer mal.delete(Allocator);
    const first_arg = try mal.sequence_nth(1);
    const first_arg_copy = try first_arg.copy(Allocator);
    const evaled = try EVAL(first_arg_copy, try env.copy(Allocator));
    const is_true = switch(evaled.data) {
        .False => false,
        .Nil => false,
        else => true,
    };
    evaled.delete(Allocator);
    if(is_true) {
        const second_arg = try mal.sequence_nth(2);
        mal_ptr.* = try second_arg.copy(Allocator);
        return;
    }
    if((try mal.sequence_length()) < 4) {
        mal_ptr.* = try MalType.new_nil(Allocator);
        return;
    }
    const third_arg = try mal.sequence_nth(3);
    const third_arg_copy = try third_arg.copy(Allocator);
    mal_ptr.* = third_arg_copy;
}

fn EVAL_fn(mal: *MalType, env: *Env) MalError!*MalType {
    defer mal.delete(Allocator);
    const arg_mal = try (try mal.sequence_nth(1)).copy(Allocator);
    const body_mal = try (try mal.sequence_nth(2)).copy(Allocator);
    const func_data = MalFuncData {
        .arg_list = arg_mal,
        .body = body_mal,
        .environment = env,
        .is_macro = false,
        .eval_func = &EVAL,
    };
    const new_func = try MalType.new_nil(Allocator);
    new_func.data = MalData{.Func = func_data};
    return new_func;
}

fn PRINT(optional_mal: ?*MalType) MalError![] u8 {
    return printer.print_str(optional_mal);
}

fn rep(environment: *Env, input: [] const u8) MalError!?[] u8 {
    var read_input = (try READ(input)) orelse return null;
    var eval_input = try EVAL(read_input, try environment.copy(Allocator));
    var print_input = try PRINT(eval_input);
    eval_input.delete(Allocator);
    return print_input;
}

fn lookup(environment: *Env, symbol: []const u8, do_warn: bool) MalError!*MalType {
     var mal = environment.get(symbol) catch |err| {
        if(do_warn) {
            const s1 = string_concat(Allocator, "'", symbol) catch return MalError.SystemError;
            const s2 = string_concat(Allocator, s1, "' not found") catch return MalError.SystemError;
            defer Allocator.free(s1);
            defer Allocator.free(s2);
            warn("'{}' not found.\n", symbol);
        }
        return MalError.KeyError;
    };
    var new_mal = try mal.copy(Allocator);
    return new_mal;
}

fn eval_ast(mal: *MalType, env: *Env) MalError!*MalType {
    defer env.delete();
    switch(mal.data) {
        .Generic => |symbol| {
            defer mal.delete(Allocator);
            return lookup(env, symbol, true);
        },
        .List => |*ll| {
            var new_ll = MalLinkedList.init(Allocator);
            var iterator = ll.iterator();
            while(iterator.next()) |next_mal| {
                const new_mal = try EVAL(next_mal, try env.copy(Allocator));
                try linked_list.append_mal(Allocator, &new_ll, new_mal);
            }
            linked_list.destroy(Allocator, ll, true);
            mal.shallow_destroy(Allocator);
            const ret_mal = MalType.new_list(Allocator, new_ll);
            return ret_mal;
        },
        .Vector => |*ll| {
            var new_ll = MalLinkedList.init(Allocator);
            var iterator = ll.iterator();
            while(iterator.next()) |next_mal| {
                const new_mal = try EVAL(next_mal, try env.copy(Allocator));
                try linked_list.append_mal(Allocator, &new_ll, new_mal);
            }
            linked_list.destroy(Allocator, ll, true);
            mal.shallow_destroy(Allocator);
            const ret_mal = MalType.new_vector(Allocator, new_ll);
            return ret_mal;
        },
        .HashMap => |hmap| {
            var new_hashmap = try MalType.new_hashmap(Allocator);
            var iterator = hmap.iterator();
            var optional_pair = iterator.next();
            while(true) {
                const pair = optional_pair orelse break;
                const key = pair.key;
                const value = pair.value;
                const evaled_value = try EVAL(value, try env.copy(Allocator));
                try new_hashmap.hashmap_insert(key, evaled_value);
                optional_pair = iterator.next();
            }
            hash_map.destroy(Allocator, hmap, true);
            mal.shallow_destroy(Allocator);
            return new_hashmap;
        },
        else => {
            return mal;
        }
    }
}

fn make_environment() MalError!*Env {
    repl_environment = try Env.new(Allocator, null);
    var environment = try repl_environment.copy(Allocator);

   for(core.core_namespace) |pair| {
        const name = pair.name;
        const func_mal: *MalType = try MalType.new_nil(Allocator);
        func_mal.data = switch(pair.func) {
            core.CorePairType.Fn0 => |func| MalData{.Fn0 = func},
            core.CorePairType.Fn1 => |func| MalData{.Fn1 = func},
            core.CorePairType.Fn2 => |func| MalData{.Fn2 = func},
            core.CorePairType.FVar => |func| MalData{.FVar = func},
            else => return MalError.TypeError,
        };
        try environment.set(name, func_mal);
    }

    const eval_mal = try MalType.new_nil(Allocator);
    eval_mal.data = MalData{.Fn1 = &eval};
    try environment.set("eval", eval_mal);
    
    const def_not_string: [] const u8 =
        \\(def! not (fn* (a) (if a false true)))
    ;
    var optional_output = try rep(environment, def_not_string);
    if(optional_output) |output| {
        Allocator.free(output);
    }

    const load_file_string: [] const u8 =
        \\(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))
    ;
    optional_output = try rep(environment, load_file_string);
    if(optional_output) |output| {
        Allocator.free(output);
    }

    return environment;
}

fn do_user_func(args: *MalLinkedList, mal_ptr: **MalType, env_ptr: **Env) MalError!void {
    const mal_func = try linked_list.pop_first(Allocator, args);
    const env = env_ptr.*;
    // First check if it is a user-defined Mal function
    if(MalTypeValue(mal_func.data) == MalTypeValue.Func) {
        const func_data = mal_func.data.Func;
        const args_ll = try func_data.arg_list.sequence_linked_list();
        const func_env = func_data.environment;
        var new_env = try Env.new(Allocator, func_env);
        func_env.delete();
        try new_env.set_list(args_ll.*, args.*);
        linked_list.destroy(Allocator, args, true);
        func_data.arg_list.delete(Allocator);
        mal_func.shallow_destroy(Allocator);
        mal_ptr.* = func_data.body;
        env.delete();
        env_ptr.* = new_env;
        return;
    }
    return MalError.TypeError;
}

pub fn main() !void {
    const stdout_file = try std.io.getStdOut();
    core.set_allocator(Allocator);
    var environment = try make_environment();

    const args = try std.process.argsAlloc(Allocator);
    var arg_list = try MalType.new_list_empty(Allocator);
    for(args) |arg,i| {
        if(i < 2) continue;
        const new_mal = try MalType.new_string(Allocator, arg);
        try arg_list.sequence_append(Allocator, new_mal);
    }
    try environment.set("*ARGV*", arg_list);

    if(args.len > 1) {
        const run_cmd = try string_concat(Allocator, try string_concat(Allocator, "(load-file \"", args[1]), "\")");
        var output = try rep(environment, run_cmd);
        return;
    }
    
    while(true) {
        var line = (try getline(Allocator)) orelse break;
        var optional_output = rep(environment, line) catch |err| {
            if(err == MalError.KeyError) {
                continue;
            } else {
                return err;
            }
        };
        if(optional_output) |output| {
            try stdout_file.write(output);
            Allocator.free(output);
            Allocator.free(line);
            try stdout_file.write("\n");
        }
    }
}
