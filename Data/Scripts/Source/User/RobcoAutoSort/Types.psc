Scriptname RobcoAutoSort:Types

Struct Filter
    Form FilterCard
    FormList Excludes
    FormList Includes
    string FormType = ""
    string DisplayTitle = ""
    Keyword CacheID
EndStruct

Struct FormVersionInfo
    Form Target
    int LatestVersion = 1
    UpdateScript UpdateScript
EndStruct

Struct ObjectVersionInfo
    string TypeSelector = ""
    int LatestVersion = 1
    UpdateScript UpdateScript
EndStruct
