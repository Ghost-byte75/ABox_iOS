#import "patcher.h"
#import "ZLogManager.h"

static NSString *const NameKey = @"CFBundleName";
static NSString *const ExecutableNameKey = @"CFBundleExecutable";

BOOL folderExists(NSString *folder){
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:folder isDirectory:&isDirectory];
    return isDirectory;
}

int cp(NSString *file, NSString *to){
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:to]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:to withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *fileName = [NSString stringWithFormat:@"%@",[file componentsSeparatedByString:@"/"].lastObject];
    NSString *realToPath = [NSString stringWithFormat:@"%@/%@",to, fileName];
    [[NSFileManager defaultManager] copyItemAtPath:file toPath:realToPath error:&error];
    return error == nil ? IPAPATCHER_SUCCESS : IPAPATCHER_FAILURE;
}

int change_binary(NSString *binaryPath, NSString *from, NSString*to) {
    NSData *originalData = [NSData dataWithContentsOfFile:binaryPath];
    NSMutableData *binary = originalData.mutableCopy;
    if (!binary)
        return IPAPATCHER_FAILURE;
    struct thin_header headers[4];
    uint32_t numHeaders = 0;
    headersFromBinary(headers, binary, &numHeaders);

    if (numHeaders == 0) {
        if(DEBUG == DEBUG_ON){
            LOG("No compatible architecture found");
        }
        return IPAPATCHER_FAILURE;
    }
    
    for (uint32_t i = 0; i < numHeaders; i++) {
        struct thin_header macho = headers[i];
        if (renameBinary(binary, macho, from, to)) {
            if(DEBUG == DEBUG_ON){
                LOG("Successfully changed  %s to %s for %s", from.UTF8String, to.UTF8String, CPU(macho.header.cputype));
                
            }
        } else {
            if(DEBUG == DEBUG_ON){
                LOG("Failed to changed  %s to %s for %s", from.UTF8String, to.UTF8String, CPU(macho.header.cputype));
            }
            return IPAPATCHER_FAILURE;
        }
    }
    if(DEBUG == DEBUG_ON){
        LOG("Writing executable to %s...", binaryPath.UTF8String);
    }
    if (![binary writeToFile:binaryPath atomically:NO]) {
        if(DEBUG == DEBUG_ON){
            LOG("Failed to write data. Permissions?");
        }
        return IPAPATCHER_FAILURE;
    }
    return IPAPATCHER_SUCCESS;
}

int remove_binary(NSString *binaryPath, NSString *dylibPath) {
    LOG("remove_binary %s", dylibPath.UTF8String);
    NSData *originalData = [NSData dataWithContentsOfFile:binaryPath];
    NSMutableData *binary = originalData.mutableCopy;
    if (!binary)
        return IPAPATCHER_FAILURE;
    struct thin_header headers[4];
    uint32_t numHeaders = 0;
    headersFromBinary(headers, binary, &numHeaders);

    if (numHeaders == 0) {
        if(DEBUG == DEBUG_ON){
            LOG("No compatible architecture found");
        }
        return IPAPATCHER_FAILURE;
    }
    
    for (uint32_t i = 0; i < numHeaders; i++) {
        struct thin_header macho = headers[i];
        if (removeLoadEntryFromBinary(binary, macho, dylibPath)) {
            LOG("Successfully removed all entries for %s", dylibPath.UTF8String);
        } else {
            LOG("No entries for %s exist to remove", dylibPath.UTF8String);
            return OPErrorNoEntries;
        }
    }
    if(DEBUG == DEBUG_ON){
        LOG("Writing executable to %s...", binaryPath.UTF8String);
    }
    if (![binary writeToFile:binaryPath atomically:NO]) {
        if(DEBUG == DEBUG_ON){
            LOG("Failed to write data. Permissions?");
        }
        return IPAPATCHER_FAILURE;
    }
    return IPAPATCHER_SUCCESS;
}

int patch_binary(NSString *binaryPath, NSString* dylibPath, NSString *lc) {
    LOG("patch_binary %s", dylibPath.UTF8String);
    NSData *originalData = [NSData dataWithContentsOfFile:binaryPath];
    NSMutableData *binary = originalData.mutableCopy;
    if (!binary)
        return IPAPATCHER_FAILURE;
    struct thin_header headers[4];
    uint32_t numHeaders = 0;
    headersFromBinary(headers, binary, &numHeaders);

    if (numHeaders == 0) {
        if(DEBUG == DEBUG_ON){
            LOG("No compatible architecture found");
        }
        return IPAPATCHER_FAILURE;
    }
    
    for (uint32_t i = 0; i < numHeaders; i++) {
        
        struct thin_header macho = headers[i];

        //NSString *lc = @"load";
        uint32_t command = LC_LOAD_DYLIB;
        if (lc)
            command = COMMAND(lc);
        if (command == -1) {
            if(DEBUG == DEBUG_ON){
                LOG("Invalid load command.");
            }
            return IPAPATCHER_FAILURE;
        }

        if (insertLoadEntryIntoBinary(dylibPath, binary, macho, command)) {
            if(DEBUG == DEBUG_ON){
                printf("Successfully inserted a %s command for %s", LC(command), CPU(macho.header.cputype));
                LOG("Successfully inserted a %s command for %s", LC(command), CPU(macho.header.cputype));
                
            }
        } else {
            if(DEBUG == DEBUG_ON){
                LOG("Failed to insert a %s command for %s", LC(command), CPU(macho.header.cputype));
            }
            return IPAPATCHER_FAILURE;
        }
    }
    if(DEBUG == DEBUG_ON){
        LOG("Writing executable to %s...", binaryPath.UTF8String);
    }
    if (![binary writeToFile:binaryPath atomically:NO]) {
        if(DEBUG == DEBUG_ON){
            LOG("Failed to write data. Permissions?");
        }
        return IPAPATCHER_FAILURE;
    }
    return IPAPATCHER_SUCCESS;
}

int patch_ipa(NSString *app_path, NSMutableArray *dylib_paths, NSString *lc_cmd, NSString *lc_path) {
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *resultDictionary = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist", app_path]];
    NSString *app_binary = @"";
            
    if (resultDictionary) {
        app_binary = [resultDictionary objectForKey:ExecutableNameKey];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZLogManager shareManager] printZipLog:@"Failed to plist data."];
        });
        return IPAPATCHER_FAILURE;
    }
    if(DEBUG == DEBUG_ON) {
        NSLog(@"App Name: %@", [resultDictionary objectForKey:NameKey]);
        NSLog(@"App Executable Name: %@", app_binary);
    }
 
    
    app_binary = [NSString stringWithFormat:@"%@/%@", app_path, app_binary];
    if(DEBUG == DEBUG_ON) {
        NSLog(@"Full app path: %@", app_binary);
    }
        
    // Create Dylibs dir
    NSString *DylibFolder = [NSString stringWithFormat:@"%@/Dylibs", app_path];

    ASSERT([fileManager createDirectoryAtPath:DylibFolder withIntermediateDirectories:true attributes:nil error:&error], @"Failed to create Dylibs directory for our application.", true);

    
    for(int i=0;i<dylib_paths.count;i++) {
        NSString *msg = [NSString stringWithFormat:@"Failed to copy %@", dylib_paths[i]];
        ASSERT(cp(dylib_paths[i], DylibFolder), msg, true);
    }
    
    bool cydiaSubstrate = false;
    NSString *libsubstrate = @"@executable_path/Dylibs/libsubstrate.dylib";

    for(int i=0;i<dylib_paths.count;i++){
        NSArray *dylibNameArray = [dylib_paths[i] componentsSeparatedByString:@"/"];
        if(DEBUG == DEBUG_ON){
            NSLog(@"array:%@", dylibNameArray);
        }
        NSString *dylibName = [NSString stringWithFormat:@"%@",dylibNameArray.lastObject];
        NSString *dylibPath = [NSString stringWithFormat:@"%@/%@", DylibFolder, dylibName];
        
        if (change_binary(dylibPath, @"/usr/lib/libsubstrate.dylib", libsubstrate) == IPAPATCHER_SUCCESS) {
            cydiaSubstrate = true;
            [[ZLogManager shareManager] printLogString:[NSString stringWithFormat:@"Successfully changed  %@ to %@ for %@", @"/usr/lib/libsubstrate.dylib", libsubstrate, dylibName]];
        }

        if (change_binary(dylibPath, @"/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", libsubstrate) == IPAPATCHER_SUCCESS) {
            cydiaSubstrate = true;
            [[ZLogManager shareManager] printLogString:[NSString stringWithFormat:@"Successfully changed  %@ to %@ for %@", @"/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", libsubstrate, dylibName]];
        }
   
        NSString *load_path = [NSString stringWithFormat:@"%@/Dylibs/%@",lc_path, dylibName];
        if (patch_binary(app_binary, load_path, lc_cmd) == IPAPATCHER_SUCCESS) {
            [[ZLogManager shareManager] printLogString:[NSString stringWithFormat:@"Inserting a %s command for %@", [lc_cmd isEqualToString:@"weak"] ? "LC_LOAD_WEAK_DYLIB" : "LC_LOAD_DYLIB", [resultDictionary objectForKey:ExecutableNameKey]]];
            [[ZLogManager shareManager] printLogString:[NSString stringWithFormat:@"注入成功：%@", load_path]];
        } else {
            [[ZLogManager shareManager] printLogString:[NSString stringWithFormat:@"注入失败：%@", load_path]];
        }
    }

    if (cydiaSubstrate) {
        // Move files into their places
        NSString *subpath1 = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"Dylib.bundle/libsubstrate" ofType:@"dylib"]];
        ASSERT(cp(subpath1, DylibFolder), @"Failed to copy over libsubstrate.dylib", true);
        // Patch the binary to load given frameworks/dylibs
        int res = patch_binary(app_binary, @"@executable_path/Dylibs/libsubstrate.dylib", lc_cmd);
        [[ZLogManager shareManager] printLogString:[NSString stringWithFormat:@"注入%@：%@", res == IPAPATCHER_SUCCESS ? @"成功" : @"失败", libsubstrate]];
    }
    
    printf("[*] Done\n");
    return IPAPATCHER_SUCCESS;
}
