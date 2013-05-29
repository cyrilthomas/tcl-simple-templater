# Helper Filters
namespace eval ::SimpleTemplater {}
namespace eval ::SimpleTemplater::helper {}
namespace eval ::SimpleTemplater::helper::html {
    proc bold { context } {
        return "<b>$context</b>"
    }

    proc italic { context } {
        return "<i>$context</i>"
    }

    proc strong { context } {
        return "<strong>$context</strong>"
    }

    proc ulist { context } {
        set result ""
        foreach element $context {
            lappend result "<li>$element</li>"
        }
        return "<ul>[join $result ""]</ul>"
    }
}
