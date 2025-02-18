#import "CDLCSubFramework.h"

@implementation CDLCSubFramework
{
    struct sub_framework_command _command;
    NSString *_name;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _command.cmd     = [cursor readInt32];
        _command.cmdsize = [cursor readInt32];
        
        uint32_t strOffset = [cursor readInt32];
        NSParameterAssert(strOffset == 12);
        
        NSUInteger length = _command.cmdsize - sizeof(_command);
        //NSLog(@"expected length: %u", length);
        
        _name = [cursor readStringOfLength:length encoding:NSASCIIStringEncoding];
        //NSLog(@"name: %@", _name);
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _command.cmd;
}

- (uint32_t)cmdsize;
{
    return _command.cmdsize;
}

@end
