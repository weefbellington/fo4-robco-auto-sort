Scriptname RobcoAutoSort:Types

; =============================================================================
; === Structs  ================================================================
; =============================================================================

Struct Filter
    Form FilterCard
    FormList Excludes
    FormList Includes
    string FormType = ""
    string DisplayTitle = ""
    Keyword CacheID
EndStruct