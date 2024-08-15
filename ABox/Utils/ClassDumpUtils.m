#import "ClassDumpUtils.h"

#import "CDClassDump.h"
#import "CDFindMethodVisitor.h"
#import "CDClassDumpVisitor.h"
#import "CDMultiFileVisitor.h"
#import "CDFile.h"
#import "CDMachOFile.h"
#import "CDFatFile.h"
#import "CDFatArch.h"
#import "CDSearchPathState.h"
#import "CDLCDylib.h"

@implementation ClassDumpUtils

+ (int)classDumpWithExecutablePath:(NSString *)path withOutput:(NSString *)outputPath {
    NSLog(@"classDumpWithPath:%@\noutputPath: %@",path, outputPath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    }
//    [[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    CDClassDump *classDump = [[CDClassDump alloc] init];
    classDump.shouldSortClasses = YES;
    classDump.shouldSortMethods = YES;
    
    CDArch targetArch = CDArchFromName(@"arm64");
    NSLog(@"chosen arch is: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
    classDump.targetArch = targetArch;

    NSString *executablePath = [path executablePathForFilename];
    NSLog(@"executablePath:%@",path);
    classDump.searchPathState.executablePath = [executablePath stringByDeletingLastPathComponent];
    CDFile *file = [CDFile fileWithContentsOfFile:executablePath searchPathState:classDump.searchPathState];

    if (file == nil) {
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        if ([defaultManager fileExistsAtPath:executablePath]) {
            if ([defaultManager isReadableFileAtPath:executablePath]) {
                NSLog(@"class-dump: Input file (%s) is neither a Mach-O file nor a fat archive.\n", [executablePath UTF8String]);
            } else {
                NSLog(@"class-dump: Input file (%s) is not readable (check read permissions).\n", [executablePath UTF8String]);
            }
        } else {
            NSLog(@"class-dump: Input file (%s) does not exist.\n", [executablePath UTF8String]);
        }
        return -1;
    } else {
        NSError *error;
        if (![classDump loadFile:file error:&error]) {
            NSLog(@"Error: %s\n", [[error localizedFailureReason] UTF8String]);
            return -1;
        } else {
            [classDump processObjectiveCData];
            [classDump registerTypes];
            CDMultiFileVisitor *multiFileVisitor = [[CDMultiFileVisitor alloc] init];
            multiFileVisitor.classDump = classDump;
            classDump.typeController.delegate = multiFileVisitor;
            multiFileVisitor.outputPath = outputPath;
            [classDump recursivelyVisit:multiFileVisitor];
            return 0;
        }
    }
}


+ (NSArray <NSString *>*)dylibLoadPathsWithExecutablePath:(NSString *)path {

    NSString *executablePath = [path executablePathForFilename];

    CDClassDump *classDump = [[CDClassDump alloc] init];
    classDump.searchPathState.executablePath = [executablePath stringByDeletingLastPathComponent];
    
    CDArch targetArch = CDArchFromName(@"arm64");
    CDFile *file = [CDFile fileWithContentsOfFile:executablePath searchPathState:classDump.searchPathState];

    CDFatFile *fatFile = [[CDFatFile alloc] initWithData:file.data filename:file.filename searchPathState:file.searchPathState];
    CDMachOFile *machOFile = [fatFile machOFileWithArch:targetArch];
    if (machOFile == nil) {
        machOFile = [[CDMachOFile alloc] initWithData:file.data filename:file.filename searchPathState:file.searchPathState];
    }
    
    NSMutableArray *dylibPaths = [NSMutableArray arrayWithCapacity:machOFile.dylibLoadCommands.count];
    for (CDLCDylib *dylib in machOFile.dylibLoadCommands) {
        NSLog(@"machOFile dylib path:%@", dylib.path);
        [dylibPaths addObject:dylib.path];
    }
    return dylibPaths.copy;
}

@end
