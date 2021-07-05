const Symbol = @This();

const std = @import("std");
const macho = std.macho;
const mem = std.mem;

const Allocator = mem.Allocator;
const Dylib = @import("Dylib.zig");
const Object = @import("Object.zig");

pub const Type = enum {
    regular,
    proxy,
    unresolved,
    tentative,
};

/// Symbol type.
@"type": Type,

/// Symbol name. Owned slice.
name: []u8,

/// Alias of.
alias: ?*Symbol = null,

/// Index in GOT table for indirection.
got_index: ?u32 = null,

/// Index in stubs table for late binding.
stubs_index: ?u32 = null,

pub const Regular = struct {
    base: Symbol,

    /// Linkage type.
    linkage: Linkage,

    /// Symbol address.
    address: u64,

    /// Section ID where the symbol resides.
    section: u8,

    /// Whether the symbol is a weak ref.
    weak_ref: bool,

    /// Object file where to locate this symbol.
    file: *Object,

    /// Debug stab if defined.
    stab: ?struct {
        /// Stab kind
        kind: enum {
            function,
            global,
            static,
        },

        /// Size of the stab.
        size: u64,
    } = null,

    /// True if symbol was already committed into the final
    /// symbol table.
    visited: bool = false,

    pub const base_type: Symbol.Type = .regular;

    pub const Linkage = enum {
        translation_unit,
        linkage_unit,
        global,
    };

    pub fn isTemp(regular: *Regular) bool {
        if (regular.linkage == .translation_unit) {
            return mem.startsWith(u8, regular.base.name, "l") or mem.startsWith(u8, regular.base.name, "L");
        }
        return false;
    }
};

pub const Proxy = struct {
    base: Symbol,

    /// Dynamic binding info - spots within the final
    /// executable where this proxy is referenced from.
    bind_info: std.ArrayListUnmanaged(struct {
        segment_id: u16,
        address: u64,
    }) = .{},

    /// Dylib where to locate this symbol.
    /// null means self-reference.
    file: ?*Dylib = null,

    pub const base_type: Symbol.Type = .proxy;

    pub fn deinit(proxy: *Proxy, allocator: *Allocator) void {
        proxy.bind_info.deinit(allocator);
    }

    pub fn dylibOrdinal(proxy: *Proxy) u16 {
        const dylib = proxy.file orelse return 0;
        return dylib.ordinal.?;
    }
};

pub const Unresolved = struct {
    base: Symbol,

    /// File where this symbol was referenced.
    /// null means synthetic, e.g., dyld_stub_binder.
    file: ?*Object = null,

    pub const base_type: Symbol.Type = .unresolved;
};

pub const Tentative = struct {
    base: Symbol,

    /// Symbol size.
    size: u64,

    /// Symbol alignment as power of two.
    alignment: u16,

    /// File where this symbol was referenced.
    file: *Object,

    pub const base_type: Symbol.Type = .tentative;
};

pub fn deinit(base: *Symbol, allocator: *Allocator) void {
    allocator.free(base.name);
    switch (base.@"type") {
        .proxy => @fieldParentPtr(Proxy, "base", base).deinit(allocator),
        else => {},
    }
}

pub fn cast(base: *Symbol, comptime T: type) ?*T {
    if (base.@"type" != T.base_type) {
        return null;
    }
    return @fieldParentPtr(T, "base", base);
}

pub fn getTopmostAlias(base: *Symbol) *Symbol {
    if (base.alias) |alias| {
        return alias.getTopmostAlias();
    }
    return base;
}

pub fn isStab(sym: macho.nlist_64) bool {
    return (macho.N_STAB & sym.n_type) != 0;
}

pub fn isPext(sym: macho.nlist_64) bool {
    return (macho.N_PEXT & sym.n_type) != 0;
}

pub fn isExt(sym: macho.nlist_64) bool {
    return (macho.N_EXT & sym.n_type) != 0;
}

pub fn isSect(sym: macho.nlist_64) bool {
    const type_ = macho.N_TYPE & sym.n_type;
    return type_ == macho.N_SECT;
}

pub fn isUndf(sym: macho.nlist_64) bool {
    const type_ = macho.N_TYPE & sym.n_type;
    return type_ == macho.N_UNDF;
}

pub fn isIndr(sym: macho.nlist_64) bool {
    const type_ = macho.N_TYPE & sym.n_type;
    return type_ == macho.N_INDR;
}

pub fn isAbs(sym: macho.nlist_64) bool {
    const type_ = macho.N_TYPE & sym.n_type;
    return type_ == macho.N_ABS;
}

pub fn isWeakDef(sym: macho.nlist_64) bool {
    return (sym.n_desc & macho.N_WEAK_DEF) != 0;
}

pub fn isWeakRef(sym: macho.nlist_64) bool {
    return (sym.n_desc & macho.N_WEAK_REF) != 0;
}
