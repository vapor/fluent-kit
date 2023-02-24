import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testCodable() throws {
        try self.testCodable_decodeError()
    }

    private func testCodable_decodeError() throws {
        let json = """
        {
          "title": "Test Question",
          "body": "Test Question Body",
          "answer": "Test Answer",
          "project": "TestProject"
        }
        """

        do {
            _ = try JSONDecoder().decode(Question.self, from: .init(json.utf8))
            XCTFail("expected error")
        } catch DecodingError.typeMismatch(let type, let context) {
            XCTAssertEqual(ObjectIdentifier(type), ObjectIdentifier(Project.self))
            XCTAssertEqual(context.codingPath.map(\.stringValue), ["project"])
        }
    }
}

final class Question: Model {
    static let schema = "questions"

    @ID(custom: "id")
    var id: Int?

    @Field(key: "title")
    var title: String

    @Field(key: "body")
    var body: String

    @Field(key: "answer")
    var answer: String

    @Parent(key: "project_id")
    var project: Project

    init() { }

    init(id: Int? = nil, title: String, body: String = "", answer: String = "", projectId: Project.IDValue) {
        self.id = id
        self.title = title
        self.body = body
        self.answer = answer
        self.$project.id = projectId
    }
}

final class Project: Model {
    static let schema = "projects"

    @ID(custom: "id")
    var id: String?

    @Field(key: "title")
    var title: String

    @Field(key: "links")
    var links: [String]

    @Children(for: \.$project)
    var questions: [Question]

    init() { }

    init(id: String, title: String, links: [String] = []) {
        self.id = id
        self.title = title
        self.links = links
    }
}
