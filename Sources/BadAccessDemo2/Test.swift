import Foundation
import SwiftXMLC

@main
struct Test {
    
    static func main() async throws {
        
        // !!! adjust path before running: !!!
        let packagePath = "/Users/stefan/Projekte/BadAccessDemo2"
        
        let paths = [
            // small example:
            "\(packagePath)/test1.xml",
        
            // same structure, but a little bigger:
            "\(packagePath)/test2.xml",
        ]
        
        await paths.forEachAsyncThrowing { path in // (forEachAsyncThrowing defined below; same result without it)
        
            // OK in both cases:
            await inner(path: path, i: 1)
            
            if #available(macOS 10.15, *) {
                await withTaskGroup(of: Void.self) { group in
                    
                    func outer() async {
                        
                        group.addTask {
                            // OK for smaller example, EXC_BAD_ACCESS for the larger example:
                            await inner(path: path, i: 2)
                        }
                    }
                    
                    await outer()
                    
                    for await _ in group {}
                }
            } else {
                print("wrong OS version")
            }
        }
    }
}

func inner(path: String, i: Int) async {
    let document = XDocument()

    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        do {
            // building a structure:
            try XParser().parse(fromData: data, eventHandlers: [XParseBuilder(document: document)])
            
            // writing it back to another file as a test:
            let copyPath = "\(path).copy\(i).xml"
            document.write(toFile: copyPath)
            
            print("\(copyPath) written")
            print("press RETURN to continue..."); _ = readLine()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    catch {
        print(error.localizedDescription)
    }
}

extension Sequence {
    func forEachAsyncThrowing (
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
