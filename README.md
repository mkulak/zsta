Sample zig program that uses dynamically loaded libraries

 Macos: ```clang -dynamiclib src/foo.c -o bar.dylib```

 Linux: ```gcc -fPIC -shared src/foo.c -o foo.so```
 
Then run: ```zig build run```

Enter `foo.dylib` then `add`