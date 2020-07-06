//
//  MatcherExtensionsTests.swift
//  Mimus
//
//  Created by Pawel Dudek on 14/08/2017.
//  Copyright © 2017 AirHelp. All rights reserved.
//

import XCTest
import Mimus

struct User: Equatable {

    let firstName: String

    let lastName: String

    let id: String
}

class MatcherExtensionsTests: XCTestCase {
    func testPassingMatcher() {
        let firstUser = User(firstName: "Fixture First Name", lastName: "Fixture Last Name", id: "42")
        let secondUser = User(firstName: "Fixture First Name", lastName: "Fixture Last Name", id: "42")

        XCTAssertTrue(firstUser.matches(argument: secondUser), "Expected users to match")
    }

    func testFailingMatcher() {
        let firstUser = User(firstName: "Fixture First Name", lastName: "Fixture Last Name", id: "42")
        let secondUser = User(firstName: "Fixture First Name", lastName: "Fixture Last Name", id: "43")

        XCTAssertFalse(firstUser.matches(argument: secondUser), "Expected users to match")
    }
}

extension User: Matcher {
    func matches(argument: Any?) -> Bool {
        return compare(other: argument as? User)
    }
}

func ==(lhs: User, rhs: User) -> Bool {
    return lhs.id == rhs.id && lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName
}
