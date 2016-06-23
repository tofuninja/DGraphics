module util.memory.noallocator;

//     _   _               _ _                 _             
//    | \ | |        /\   | | |               | |            
//    |  \| | ___   /  \  | | | ___   ___ __ _| |_ ___  _ __ 
//    | . ` |/ _ \ / /\ \ | | |/ _ \ / __/ _` | __/ _ \| '__|
//    | |\  | (_) / ____ \| | | (_) | (_| (_| | || (_) | |   
//    |_| \_|\___/_/    \_\_|_|\___/ \___\__,_|\__\___/|_|   
//                                                           
//                                                                                                                                    

/// Ensures that no allocation happens 
struct NoAllocator
{
    import std.experimental.allocator.common : Ternary;
    enum uint alignment = 64 * 1024;
    void[] allocate(size_t) shared                              { assert(false); }
    void[] alignedAllocate(size_t, uint) shared                 { assert(false); }
    void[] allocateAll() shared                                 { assert(false); }
    bool expand(ref void[] b, size_t) shared                    { assert(false); }
    bool reallocate(ref void[] b, size_t) shared                { assert(false); }
    bool alignedReallocate(ref void[] b, size_t, uint) shared   { assert(false); }
    Ternary owns(void[]) shared const                           { return Ternary.no; }
    void[] resolveInternalPointer(void*) shared const           { assert(false); }
    bool deallocate(void[] b) shared                            { assert(false); }
    bool deallocateAll() shared                                 { return true; }
    Ternary empty() shared const                                { return Ternary.yes; }
    static shared NoAllocator instance;
}

