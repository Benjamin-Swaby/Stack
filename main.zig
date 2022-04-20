const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const stdin = std.io.getStdIn().reader();
const testing = std.testing;


// The size of the stack hardcoded
const STACK_SIZE :i16 = 6;


// Errors relating to type manipulation &
// conversion
const TypeError = error {
    IntOverflow,
    WrongDataType,
    IoError,
    CommandError,
};


// Errors relating to stack operations
const StackError = error {
    StackOverflow,
    StackUnderflow,
    CreationError,
    PeekError,
    StackEmpty,
};


// simple type enum to decide if an element
// will store a word/phrase or a number
const Type = enum {
    string,
    number,
};


// stack element:
// contains a data buffer and a type
// the value is stored as a "string" until needed to be
// converted to an integer
const stack_element = struct {
    data_buffer: [100]u8,
    data_type: Type,

    // function to get the numerical value of the given string
    pub fn value(self :stack_element) TypeError!i64{
        if (self.data_type != Type.number) {
            return TypeError.WrongDataType;
        } else {

            var count: i64 = 0;
            
            for (self.data_buffer) |element| {

                // redundant check for numbers (can also be used for terminating)

                if (element > 48 and element < 57) {
                    count = count * 10;
                    count += (element - 48);
                }
                
            }

            return count;
            
        }

        //TODO return int type
    }
};


// stack:
// contains an array of (6) stack elements,
// and a pointer to show the position of the stack
// this allows a stack to be easily copied and mutated externally
// however mutating the pointer is potentially dangerous
const stack = struct {
    
    // the array of elements
    contents: [STACK_SIZE]stack_element,
    
    // pointer will point at the current index (starts at -1)
    ptr: i16,

    // push an element to the front of the stack
    pub fn push(self :*stack, se :stack_element) StackError!void {
                
        if (self.ptr < (STACK_SIZE - 1)) {
            self.ptr += 1;
            self.contents[@intCast(u8,self.ptr)] = se;
        } else {
            return StackError.StackOverflow;
        }
        
    }

    // pop an element from the front of the stack
    pub fn pop(self :*stack) StackError!void {

        if (self.ptr > -1) {
            self.contents[@intCast(u8,self.ptr)] = undefined;
            self.ptr -= 1;
        } else {
            return StackError.StackUnderflow;
        }      
    }

    // return the first element of the stack
    pub fn peek(self :stack) StackError!stack_element{

        if (self.ptr >= 0) {
            return self.contents[@intCast(u8,self.ptr)];
        }
        
        return StackError.StackEmpty;
    }
};


fn output(my_stack :*stack) !void{
  
    if (my_stack.peek()) |elem| {
        // print and format the element

        if (elem.data_type == Type.string) {
            // print as String
            print("Element Type String\n\r",.{});
            print("Value = {s}\n\r",.{elem.data_buffer});
        }else {
            print("Element Type Integer\n\r",.{});
            print("Value as int = {}\n\r",.{elem.value()});
        }
        
    } else |err| switch (err) {
        error.StackEmpty => print("Cannot read from empty stack\n\r",.{}),
        else => @panic("Unexpected Error from Stack Peek!"),
    }
}


// Prompt:
// Ask the User for an input, parse the input and execute the correct
// stack method
fn prompt(my_stack :*stack) !void {
   
    var buf: [100]u8 = undefined; //input buffer

    print("Enter Command [{}](+,-,?): ", .{my_stack.ptr + 1}); // prompt

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        
        if (user_input[0] == 43) { // +
            //push

            var only_num: bool = true;
            var se: stack_element = undefined;
            var count: u32 = 0;

            
            
            for (user_input) |char| {
                // skip the first value;
                if(count == 0) {
                    count += 1;
                    continue;
                }

                // check if input contains only numbers
                if(only_num) {
                    if (char < 48 or char > 57) {
                        only_num = false;
                    }
                }

                // fill data buffer
                se.data_buffer[count] = char;
                count += 1;
            }

            // set data type
            if(only_num) {
                se.data_type = Type.number;
            } else {
                se.data_type = Type.string;
            }

            // push the element to the stack
            if(my_stack.push(se)) {
               
            }else |err| switch(err) {
                error.StackOverflow => print("Cannot push to a full stack\n\r",.{}),
                else => @panic("Unexpected Error from Stack Push"),
            }
           
            
        } else if (user_input[0] == 45) { // -

            
            // try remove an element from the stack
            if(my_stack.pop()) {
                
            } else |err| switch(err) {
                error.StackUnderflow => print("Cannot pop from an empty stack \n\r",.{}),
                else => @panic("Unexpected Error from Stack Pop"),
            } 

        } else if (user_input[0] == 63) { // ?
            try output(my_stack);
        } else {
            return TypeError.CommandError;
        }
        
    } else {
        return TypeError.IoError;
    }
}



// Entry Point
pub fn main() anyerror!void {
    print("Stack Program V1.0 By Benjamin Swaby\n\r",.{});
    print("+ : push \n- : pop \n? : peek\n\r",.{});
    print("Example : +45 : add 45 to the stack\n\r",.{});
    var my_stack: stack = undefined;
    my_stack.ptr = -1;

    while (true) {
        if (prompt(&my_stack)){
            
        } else |err| switch (err) {
            error.CommandError => print("Not a valid Command \n\r",.{}),
            error.IoError => print("Count not get Input\n\r", .{}),
            else => @panic("Unexpected Error from prompt"),
        }
    }
}

test "Stack Creation" {
    var my_stack :stack = undefined;
    my_stack.ptr = -1;
    try testing.expectEqual(my_stack.ptr,-1);
}

test "Read From Empty Stack" {
    var my_stack :stack = undefined;
    my_stack.ptr = -1;
    
    if (my_stack.peek()) {
        @panic("Empty Stack did not return Error");
    } else |err| switch (err) {
        error.StackEmpty => {},
        else => @panic("Unexpected Error from Stack Peek!"),
    }
}


test "Pop From Empty Stack" {
    var my_stack :stack = undefined;
    my_stack.ptr = -1;

    if (my_stack.pop()) {
        @panic("Empty Stack should not pop");
    } else |err| switch (err) {
        error.StackUnderflow => {},
        else => @panic("Empty Stack returned unexpected Error"),
    } 
}
