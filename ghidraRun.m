@import Foundation;

int main() {
    execl([NSBundle.mainBundle.resourcePath stringByAppendingString:@"/ghidra/ghidraRun"].UTF8String, NULL);
}
