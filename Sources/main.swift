import Foundation
import AsyncHTTPClient
import NIO

struct GameStartResponse: Codable {
    let game_id: String
}

struct GameGuessRequest: Codable {
    let game_id: String
    let guess: String
}

struct GameGuessResponse: Codable {
    let black: Int
    let white: Int
}

@main
struct MastermindGame {
    static func main() async {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(group))

        func createGame() async throws -> String {
            var request = HTTPClientRequest(url: "https://mastermind.darkube.app/game")
            request.method = .POST
            request.headers.add(name: "Accept", value: "application/json")
            request.body = .bytes(ByteBuffer(string: ""))

            let response = try await client.execute(request, timeout: .seconds(10))
            let body = try await response.body.collect(upTo: 1024)
            let data = body.getBytes(at: body.readerIndex, length: body.readableBytes).map { Data($0) } ?? Data()
            return try JSONDecoder().decode(GameStartResponse.self, from: data).game_id
        }

        func makeGuess(gameId: String, digits: [Int]) async throws -> GameGuessResponse {
            let guessString = digits.map(String.init).joined()
            let payload = GameGuessRequest(game_id: gameId, guess: guessString)
            let encoded = try JSONEncoder().encode(payload)

            var buffer = ByteBufferAllocator().buffer(capacity: encoded.count)
            buffer.writeBytes(encoded)

            var request = HTTPClientRequest(url: "https://mastermind.darkube.app/guess")
            request.method = .POST
            request.headers.add(name: "Content-Type", value: "application/json")
            request.body = .bytes(buffer)

            let response = try await client.execute(request, timeout: .seconds(10))
            let body = try await response.body.collect(upTo: 1024)
            let bytes = body.getBytes(at: body.readerIndex, length: body.readableBytes) ?? []
            let data = Data(bytes)

            // if let raw = String(data: data, encoding: .utf8) {
                // throw NSError(domain: "GuessError", code: 999, userInfo: [
                    // NSLocalizedDescriptionKey: "Server error: \(raw)"
                // ])
            // } else {
                // throw NSError(domain: "GuessError", code: 998, userInfo: [
                    // NSLocalizedDescriptionKey: "Server returned an unreadable response."
                // ])
            // }

            if let feedback = try? JSONDecoder().decode(GameGuessResponse.self, from: data) {
                return feedback
            }

            struct ServerError: Codable {
                let error: String
            }

            if let serverError = try? JSONDecoder().decode(ServerError.self, from: data) {
                throw NSError(domain: "GuessError", code: 999, userInfo: [
                    NSLocalizedDescriptionKey: "⚠️ \(serverError.error)"
                ])
            }

            throw NSError(domain: "GuessError", code: 998, userInfo: [
                NSLocalizedDescriptionKey: "Server returned an unreadable or unexpected response."
            ])
        }


        func isValid(_ input: String) -> Bool {
            return input.count == 4 && input.allSatisfy { "123456".contains($0) }
        }

        do {
            let gameId = try await createGame()
            print("\n🎮 Game started! Your Game ID: \(gameId)")
            print("\nGuess the 4-digit code. Digits range from 1 to 6 and must be unique.\n")
            print("You have unlimited attempts!\n")
            print("🎯 Feedback Guide:")
            print("B = Correct digit in the correct position")
            print("W = Correct digit but in the wrong position\n")
            print("Example: If the code is 1234 and you guess 1243, the feedback will be: BBWW")
            print("Type 'exit' at any time to quit the game.\n")

            var attempt = 1
            while true {
                print("Attempt \(attempt): Enter guess or 'exit': ", terminator: "")
                guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    continue
                }

                if input.lowercased() == "exit" {
                    print("👋 Exiting. See you next time!")
                    break
                }

                guard isValid(input) else {
                    print("⚠️ Invalid guess. Use exactly 4 digits from 1–6.")
                    continue
                }

                let guess = input.compactMap { Int(String($0)) }

                do {
                    let feedback = try await makeGuess(gameId: gameId, digits: guess)
                    let result = String(repeating: "B", count: feedback.black) + String(repeating: "W", count: feedback.white)
                    print("Feedback: \(result)\n")

                    if feedback.black == 4 {
                        print("🎉 You cracked the code in \(attempt) attempts!")
                        break
                    }
                } catch {
                    print("\(error.localizedDescription)")
                }

                attempt += 1
            }
        } catch {
            print("❌ Could not start game: \(error)")
        }

        try? await client.shutdown()
        try? await group.shutdownGracefully()
    }
}
