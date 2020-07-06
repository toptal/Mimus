//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest
@testable import Mimus

class FakeVerificationHandler: VerificationHandler {

    var lastCallIdentifier: String?
    var lastMatchedResults: [MimusComparator.ComparisonResult]?
    var lastMismatchedArgumentsResults: [MimusComparator.ComparisonResult]?
    var lastMode: VerificationMode?
    var lastTestLocation: TestLocation?

    override func verifyCall(callIdentifier: String, matchedResults: [MimusComparator.ComparisonResult], mismatchedArgumentsResults: [MimusComparator.ComparisonResult], mode: VerificationMode, testLocation: TestLocation) {
        lastCallIdentifier = callIdentifier
        lastMatchedResults = matchedResults
        lastMismatchedArgumentsResults = mismatchedArgumentsResults
        lastTestLocation = testLocation
        lastMode = mode
    }
}

class MockTests: XCTestCase {

    class MockRecorder: Mock {
        var storage = Storage()
    }

    var mockRecorder: MockRecorder!
    var fakeVerificationHandler: FakeVerificationHandler!

    override func setUp() {
        super.setUp()

        mockRecorder = MockRecorder()
        fakeVerificationHandler = FakeVerificationHandler()

        VerificationHandler.shared = fakeVerificationHandler
    }

    override func tearDown() {
        mockRecorder = nil
        fakeVerificationHandler = nil

        VerificationHandler.shared = VerificationHandler()
    }

    // MARK: Test No Recorder Invocations

    func testNoRecorderInvocations() {
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier")

        XCTAssertEqual(fakeVerificationHandler.lastCallIdentifier, "Fixture Identifier", "Expected verification handler to receive correct call identifier")
    }

    func testBaseVerificationMode() {
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier")

        XCTAssertEqual(fakeVerificationHandler.lastMode, VerificationMode.times(1), "Expected verification handler to receive default verification mode")
    }

    func testCustomVerificationMode() {
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", mode: .never)

        XCTAssertEqual(fakeVerificationHandler.lastMode, VerificationMode.never, "Expected verification handler to receive correct custom verification mode")
    }

    func testCorrectFileLocation() {
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", file: "Fixture File", line: 42)

        let expectedFileName: StaticString = "Fixture File"
        // Not too beautiful - we're using our matchers as XCTest cannot verify StaticStrings
        let namesMatched = expectedFileName.matches(argument: fakeVerificationHandler.lastTestLocation?.file)

        XCTAssertTrue(namesMatched, "Expected verification handler to receive correct file")
        XCTAssertEqual(fakeVerificationHandler.lastTestLocation?.line, 42, "Expected verification handler to receive correct line")
    }

    func testCorrectNumberOfMatches() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier 2")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier 3")

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier")

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 2, "Expected verification handler to receive correct number of matches")
    }

    func testCorrectNumberOfMatchesWithArguments() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [42, 43])
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [42, 43])
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier 2")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier 3")

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [42, 43])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 2, "Expected verification handler to receive correct number of matches")
    }

    func testCorrectNumberOfMismatchedArguments() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [42])
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [43])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [42])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
        XCTAssertEqual(fakeVerificationHandler.lastMismatchedArgumentsResults?.count, 2, "Expected verification handler to receive correct number of unmatched arguments")
    }

    func testCaptureArgument() {
        let argumentCaptor = CaptureArgumentMatcher()

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [42])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [argumentCaptor])

        let lastValue: Int? = argumentCaptor.lastValue()

        XCTAssertEqual(lastValue, 42, "Expected to receive captured value")
    }

    func testInstanceOf() {
        let user = User(identifier: "Fixture Identifier")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [user])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [InstanceOf<User>()])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testInstanceOfShorthand() {
        let user = User(identifier: "Fixture Identifier")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [user])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mInstanceOf(User.self)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testInstanceOfFailure() {
        let user = User(identifier: "Fixture Identifier")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [user])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [InstanceOf<Client>()])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    // MARK: Identical

    func testIdentical() {
        let object = TestClass()

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mIdentical(object)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testIdenticalNilObjects() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [nil])

        let value: AnyObject? = nil
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mIdentical(value)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testIdenticalFailure() {
        let object = TestClass()
        let otherObject = TestClass()

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mIdentical(otherObject)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    func testIdenticalNilObjectFailure() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [nil])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mIdentical(TestClass())])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    func testIdenticalNilObjectInMatcherFailure() {
        let object = TestClass()
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])

        let value: AnyObject? = nil
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mIdentical(value)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    func testIdenticalFailureDifferentObject() {
        let otherObject = TestClass()

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: ["Fixture String"])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mIdentical(otherObject)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    // MARK: Equal

    func testEqual() {
        let object = TestStruct(value: "Fixture Value 1")
        let anotherObject = TestStruct(value: "Fixture Value 1")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mEqual(anotherObject)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testEqualNilObjects() {
        let object: TestStruct? = nil

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [nil])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mEqual(object)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testArrayEqual() {
        let object = TestStruct(value: "Fixture Value 1")
        let anotherObject = TestStruct(value: "Fixture Value 1")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [[object]])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [[mEqual(anotherObject)]])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testEqualFailure() {
        let object = TestStruct(value: "Fixture Value 1")
        let anotherObject = TestStruct(value: "Fixture Value 2")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mEqual(anotherObject)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    func testEqualNilObjectFailure() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [nil])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mEqual(TestStruct(value: "Fixture Value 1"))])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    func testEqualNilObjectInMatcherFailure() {
        let object = TestStruct(value: "Fixture Value 1")
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])

        let value: TestStruct? = nil
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mEqual(value)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    func testEqualFailureDifferentObjects() {
        let anotherObject = TestStruct(value: "Fixture Value 2")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: ["Fixture String"])

        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mEqual(anotherObject)])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    // MARK: Closure Matcher

    func testClosureSuccess() {
        let object = TestStruct(value: "Fixture Value 1")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])

        let matcher = ClosureMatcher<TestStruct>({ v in
            return v?.value == object.value
        })
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [matcher])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testClosureShorthandSuccess() {
        let object = TestStruct(value: "Fixture Value 1")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])

        let matcher = mClosure({ (v: TestStruct?) in
            return v?.value == object.value
        })
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [matcher])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testClosureSuccessWithNil() {
        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [nil])

        let matcher = ClosureMatcher<TestStruct>({ v in
            return v == nil
        })
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [matcher])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testClosureFailure() {
        let object = TestStruct(value: "Fixture Value 1")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])
        let matcher = ClosureMatcher<TestStruct>({ v in
            return v?.value == "Different Value"
        })
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [matcher])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }


    func testClosureFailureIncorrectTypeCast() {
        let object = TestStruct(value: "Fixture Value 1")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])
        let matcher = ClosureMatcher<User>({ v in
            return true
        })
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [matcher])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    // MARK: Not Matcher

    func testNotSuccess() {
        let object = TestStruct(value: "Fixture Value 1")
        let anotherObject = TestStruct(value: "Fixture Value 2")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mNot(mEqual(anotherObject))])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 1, "Expected verification handler to receive correct number of matches")
    }

    func testNotFailure() {
        let object = TestStruct(value: "Fixture Value 1")

        mockRecorder.recordCall(withIdentifier: "Fixture Identifier", arguments: [object])
        mockRecorder.verifyCall(withIdentifier: "Fixture Identifier", arguments: [mNot(mEqual(object))])

        XCTAssertEqual(fakeVerificationHandler.lastMatchedResults?.count, 0, "Expected verification handler to receive correct number of matches")
    }

    // MARK: Helpers

    struct User {
        let identifier: String
    }

    struct Client {
        let identifier: String
    }

    class TestClass {

    }

    struct TestStruct: Equatable {
        static func ==(lhs: TestStruct, rhs: TestStruct) -> Bool {
            return lhs.value == rhs.value
        }

        let value: String
    }
}
