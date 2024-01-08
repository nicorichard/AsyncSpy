# AsyncSpy

Declare expectations for asynchronous effects easily and reliably in your tests.

> 🚨 Warning: This library is not yet stable and is more a representation of my self-education on writing efficient, simple, and reproducable asynchronous tests

## Usage

```swift
import AsyncSpy

func test() async {
    let events = [1, 2, 3].publisher
    
    let spy = AsyncSpy(subject: subject.values)
    
    await spy.expect(1)
    await spy.expect(2)
    await spy.expect(3)
}
```
