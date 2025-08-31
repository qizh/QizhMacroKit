import Testing
import QizhMacroKit

@Suite("IsCase macro")
struct IsCaseMacroTests {
        @Test("Generated properties")
        func generatedProperties() {
                @IsCase
                enum TestEnum {
                        case first
                        case second(Int)
                        case third(String)
                }

                let value1 = TestEnum.first
                #expect(value1.isFirst)
                #expect(!value1.isSecond)
                #expect(!value1.isThird)

                let value2 = TestEnum.second(42)
                #expect(!value2.isFirst)
                #expect(value2.isSecond)
                #expect(!value2.isThird)

                let value3 = TestEnum.third("Hello")
                #expect(!value3.isFirst)
                #expect(!value3.isSecond)
                #expect(value3.isThird)
        }

        @Test("Case membership functions")
        func caseMembership() {
                @IsCase
                enum Actions {
                        case setup(api: String)
                        case update
                        case cache
                        case export(target: String)
                        case `import`(String)
                        case sync
                        case process
                }

                let nextAction: Actions = .sync
                #expect(nextAction.isAmong([.setup, .update, .sync]))
                #expect(!nextAction.isAmong(.export, .import))
        }

        @Test("Escapes uppercase Swift keywords")
        func escapesUppercaseSwiftKeywords() {
                @IsCase
                enum Keywords {
                        case `Any`
                        case value
                }

                let keyword: Keywords = .Any
                #expect(keyword.isAny)
                #expect(!keyword.isValue)
                #expect(keyword.isAmong(.`Any`))
        }
}
