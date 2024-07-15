const std = @import("std");
const rand = std.crypto.random;
const ls = @import("../lib/lc.zig");
const vops = @import("../lib/vector.zig");
const print = std.debug.print;

pub fn run() !void {
    const epsilon: f32 = 0.0001;
    const K: comptime_int = 2; // number of clusters to build
    const DIMS = 3;
    const vOps3Dimf32 = vops.VectorOps(3, f32);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();
    var kmeans_groups = LinkedList(@Vector(DIMS, f32)).init(&allocator);
    var clusters = std.ArrayList(std.ArrayList(@Vector(DIMS, f32))).init(allocator);
    defer clusters.deinit();
    var tempCentroids = std.ArrayList(@Vector(DIMS, f32)).init(allocator);
    defer tempCentroids.deinit();
    defer kmeans_groups.removeAll();

    const stdin = std.io.getStdIn();
    const stdinReader = stdin.reader();

    var buf: [1024]u8 = undefined;
    var writer = std.io.fixedBufferStream(&buf);

    var centroids = std.ArrayList(@Vector(DIMS, f32)).init(allocator);
    var vecData = std.ArrayList(@Vector(DIMS, f32)).init(allocator);
    defer centroids.deinit();
    defer vecData.deinit();

    while (true) {
        defer writer.reset();
        // read the file line by line writing into buf
        stdinReader.streamUntilDelimiter(writer.writer(), '\n', null) catch |err| {
            switch (err) {
                error.EndOfStream => {
                    break;
                },
                else => {
                    print("{any}", .{err});
                    break;
                },
            }
        };

        // parse the json array as a fixed size f32 array
        const arr = std.json.parseFromSlice([DIMS]f32, allocator, buf[0..writer.pos], .{}) catch |err| {
            switch (err) {
                error.UnexpectedEndOfInput => {
                    break;
                },
                else => {
                    print("{any}", .{err});
                    break;
                },
            }
        };
        // add the json parsed string to the vecData as a Vector(N,T) type
        try vecData.append(arr.value);
        defer arr.deinit();
    }

    // pick random points to use as centroids
    for (0..K) |_| {
        const d = rand.intRangeAtMost(usize, 0, vecData.items.len);
        try centroids.append(vecData.items[d]);
    }
    // Initialize the arraylists that will contain the vectors for each centroid
    for (0..K) |_| {
        try clusters.append(std.ArrayList(@Vector(DIMS, f32)).init(allocator));
    }

    // for (centroids.items) |item| {
    //     std.debug.print("{any}\n", .{item});
    // }
    for (centroids.items) |item| {
        std.debug.print("centroid {any}\n", .{item});
    }

    for (0..10) |j| {
        std.debug.print("round ----- {d}\n", .{j});
        for (vecData.items) |vec| {
            var belongsTo: usize = 0; // the index of the cluster we assign the vector to
            var minDist: f32 = std.math.inf(f32);
            for (centroids.items, 0..) |centroid, i| {
                const dist: f32 = vOps3Dimf32.dist(vec, centroid);
                if (dist < minDist) {
                    minDist = dist;
                    belongsTo = i;
                }
            }
            std.debug.print("assigning {any} - {any}\n", .{ belongsTo, vec });
            try clusters.items[belongsTo].append(vec);
        }

        for (clusters.items) |cluster| {
            const centroid_for_cluster = vOps3Dimf32.centroid(cluster);
            try tempCentroids.append(centroid_for_cluster);
        }

        var moved: bool = false;
        for (centroids.items, tempCentroids.items) |old, new| {
            if (vOps3Dimf32.dist(old, new) > epsilon) {
                moved = true;
                break;
            }
        }

        // if we did not move, then we have good enough centroids
        // the cleaup and releasing of resources is left up to the
        // defer statements
        if (!moved) {
            for (centroids.items, clusters.items) |centroid, clusters_items| {
                try kmeans_groups.append(centroid, clusters_items);
            }

            return;
        }

        // copy over the newly calculated centroids into the main centroids
        // collection
        centroids.clearRetainingCapacity();
        for (tempCentroids.items) |item| {
            try centroids.append(item);
        }
        tempCentroids.clearRetainingCapacity();

        // clean up all clusters as well since we are going to re-calculate
        // them all on the next loop
        for (clusters.items) |*c| {
            c.clearRetainingCapacity();
        }
    }
    kmeans_groups.print();

    // std.debug.print("{d}\n", .{vecData.items[0]});
    // std.debug.print("{d}\n", .{d});
}
pub fn LinkedList(comptime T: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            centroid: T,
            members: std.ArrayList(T),
            next: ?*Node,
        };

        allocator: *std.mem.Allocator,
        head: ?*Node,
        len: usize,

        pub fn init(allocator: *std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .head = null,
                .len = 0,
            };
        }

        pub fn append(self: *This, centroid: T, members: std.ArrayList(T)) !void {
            const new_node: *Node = try self.allocator.create(Node);
            new_node.* = Node{ .centroid = centroid, .members = members, .next = self.head };
            self.head = new_node;
            self.len += 1;
        }

        pub fn removeAll(self: *This) void {
            var current_node: ?*Node = self.head;
            while (current_node) |node| {
                current_node = node.next;

                node.members.deinit();
                self.allocator.destroy(node);
            }
            self.head = null;
            self.len = 0;
        }

        pub fn print(self: *This) void {
            var current_node = self.head;
            while (current_node) |node| {
                std.debug.print("centroid {any}\n", .{node.centroid});
                for (node.members.items) |member| {
                    std.debug.print("\tmember {any}\n", .{member});
                }
                current_node = node.next;
            }
        }
    };
}
// var thread_pool: std.Thread.Pool = undefined;
//    try thread_pool.init(.{ .allocator = gpa, .n_jobs = 12 });
//    defer thread_pool.deinit();
//
//    while (true) {
//        std.debug.print("wait\n", .{});
//        var resp: std.http.Server.Response = try std.http.Server.accept(&server, .{ .allocator = gpa2 });
//        std.debug.print("conn rec\n", .{});
//        thread_pool.spawn(handleConnection, .{&resp}) catch |err| {
//            std.log.err("error spawning thread {any}", .{err});
//        };
//    }
