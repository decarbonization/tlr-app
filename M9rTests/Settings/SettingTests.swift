/*
 * M9r
 * Copyright (C) 2025  MAINTAINERS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation
import Testing
@testable import M9r

extension UserDefaults {
    fileprivate static var testing: UserDefaults! {
        UserDefaults(suiteName: "io.github.decarbonization.M9r.testing")
    }
}

@Suite struct SettingTests {
    struct Name: Equatable, Codable {
        var first: String
        var last: String
    }
    
    // MARK: -
    
    @Test func codable() {
        enum Specimen {
            @Setting("codable", storage: .testing) static var subject = Name(first: "Bad", last: "Bunny")
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == Name(first: "Bad", last: "Bunny"))
        
        Specimen.subject = Name(first: "The", last: "Weeknd")
        #expect(Specimen.subject == Name(first: "The", last: "Weeknd"))
    }
    
    @Test func optionalCodable() {
        enum Specimen {
            @Setting("optionalCodable", storage: .testing) static var subject: Name?
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == nil)
        
        Specimen.subject = Name(first: "The", last: "Weeknd")
        #expect(Specimen.subject == Name(first: "The", last: "Weeknd"))
    }
    
    // MARK: -
    
    @Test func bool() {
        enum Specimen {
            @Setting("bool", storage: .testing) static var subject = false
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == false)
        
        Specimen.subject = true
        #expect(Specimen.subject == true)
    }
    
    @Test func optionalBool() {
        enum Specimen {
            @Setting("optionalBool", storage: .testing) static var subject: Bool?
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == nil)
        
        Specimen.subject = true
        #expect(Specimen.subject == true)
    }
    
    @Test func double() {
        enum Specimen {
            @Setting("double", storage: .testing) static var subject = 0.42
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == 0.42)
        
        Specimen.subject = 0.99
        #expect(Specimen.subject == 0.99)
    }
    
    @Test func optionalDouble() {
        enum Specimen {
            @Setting("optionalDouble", storage: .testing) static var subject: Double?
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == nil)
        
        Specimen.subject = 0.99
        #expect(Specimen.subject == 0.99)
    }
    
    @Test func int() {
        enum Specimen {
            @Setting("int", storage: .testing) static var subject = 42
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == 42)
        
        Specimen.subject = 99
        #expect(Specimen.subject == 99)
    }
    
    @Test func optionalInt() {
        enum Specimen {
            @Setting("optionalInt", storage: .testing) static var subject: Int?
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == nil)
        
        Specimen.subject = 99
        #expect(Specimen.subject == 99)
    }
    
    @Test func string() {
        enum Specimen {
            @Setting("string", storage: .testing) static var subject = "hello"
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == "hello")
        
        Specimen.subject = "bonjour"
        #expect(Specimen.subject == "bonjour")
    }
    
    @Test func optionalString() {
        enum Specimen {
            @Setting("optionalString", storage: .testing) static var subject: String?
            
            static func prepare() {
                _subject.reset()
            }
        }
        
        Specimen.prepare()
        #expect(Specimen.subject == nil)
        
        Specimen.subject = "bonjour"
        #expect(Specimen.subject == "bonjour")
    }
}
