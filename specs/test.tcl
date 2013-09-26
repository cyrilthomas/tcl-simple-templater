source ~/tcl_projects/SimpleTemplater/SimpleTemplater.tcl

describe "process line" {
    context "when a variable" {
        it "wraps the variable to the context checker and encodes it" {
            expect [::SimpleTemplater::processLine "Hello {{name}}"] to equal {Hello [::SimpleTemplater::htmlEscape [::SimpleTemplater::objectExists ::SimpleTemplater::object name 1] 0]}
        }
    }

    context "when given multiple variables" {
        it "wraps the variables to the context checker and encodes it" {
            expect [::SimpleTemplater::processLine "Hello {{firstname}} {{lastname}}"] to equal \
                {Hello [::SimpleTemplater::htmlEscape [::SimpleTemplater::objectExists ::SimpleTemplater::object firstname 1] 0] [::SimpleTemplater::htmlEscape [::SimpleTemplater::objectExists ::SimpleTemplater::object lastname 1] 0]}
        }
    }
}

describe "parser" {

    before each {
        # ::SimpleTemplater::setConfig -debug true
    }

    context "if loop" {
        it "loop on left and static data on right-side" {
            set template ""
            lappend template {{% if loop.count == "1" %}}
            mock_call "::SimpleTemplater::processFunc_if"
            ::SimpleTemplater::parser template
        }

        it "loop on right and static data on left-side" {
            set template ""
            lappend template {{% if "1" == loop.count %}}
            mock_call "::SimpleTemplater::processFunc_if"
            ::SimpleTemplater::parser template
        }

        it "object at left and right-side" {
            set template ""
            lappend template {{% if loop.count == address.name.0 %}}
            mock_call "::SimpleTemplater::processFunc_if"
            ::SimpleTemplater::parser template
        }

        it "object at right-side" {
            set template ""
            lappend template {{% if "1" == address.name.0 %}}
            mock_call "::SimpleTemplater::processFunc_if"
            ::SimpleTemplater::parser template
        }
    }

    context "for loop with single iterator" {

        it "works with object" {
            set template ""
            lappend template {{% for addr in address.data.0 %}}
            mock_call "::SimpleTemplater::processFunc_for"
            ::SimpleTemplater::parser template
        }

        it "works with static data" {
            set template ""
            lappend template {{% for addr in "10 20 30" %}}
            mock_call "::SimpleTemplater::processFunc_for"
            ::SimpleTemplater::parser template
        }

        it "works with filters" {
            set template ""
            lappend template {{% for addr in address|safe:"a,b,c"%}}
            mock_call "::SimpleTemplater::processFunc_for"
            ::SimpleTemplater::parser template
        }

        it "works with loop count" {
            set template ""
            lappend template {{% for addr in loop.count %}}
            mock_call "::SimpleTemplater::processFunc_for"
            ::SimpleTemplater::parser template
        }
    }
}
