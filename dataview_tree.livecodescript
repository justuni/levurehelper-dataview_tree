script "DataView Tree Behavior" with behavior "DataView Behavior"
constant kBuiltInProperties = "id,type,expanded,is leaf,children,level,child count"

local sTreeA
local sNodeIdNodeLookupA # key = node id, value = node index array in sTreeA
local sRowNodeIdLookupA # key = row, value = node id. Lookup in sNodeIdNodeLookupA.
local sNodeIdRowLookupA # key = node id, value = row number
local sRebuildLookupTable = false

/**
Summary: Sets the tree used to display source tree data.

Parameters:
pTreeA: An array representing tree used to draw the tree in the DataView.

Description:
The DataView uses an array that is populated with node arrays. A node array has
the following format:

```
pNodeA[type|id|expanded|children|is leaf]
```

A node can have other nodes as `children`. A tree is made up of one or more
nodes.

```
pTreeA[1][type|id|expanded|children|is leaf]
pTreeA[n][type|id|expanded|children|is leaf]
```

Here is an example of a tree with three nodes – one node at the root, one node
as a child of the root node, and one node as the child of the child of the root node.

```
pTreeA[1]["type"]
pTreeA[1]["id"]
pTreeA[1]["expanded"]
pTreeA[1]["is leaf"]
pTreeA[1]["children"]
pTreeA[1]["children"][1]["type"]
pTreeA[1]["children"][1]["id"]
pTreeA[1]["children"][1]["expanded"]
pTreeA[1]["children"][1]["is leaf"]
pTreeA[1]["children"][1]["children"]
pTreeA[1]["children"][1]["children"][1]["type"]
pTreeA[1]["children"][1]["children"][1]["id"]
pTreeA[1]["children"][1]["children"][1]["expanded"]
pTreeA[1]["children"][1]["children"][1]["is leaf"]
pTreeA[1]["children"][1]["children"][1]["children"]
```

At a minimum you should define the `type` and `id` properties for each node.
`id` should uniquely identify the node in the entire tree. `type` is used to
distinguish nodes from each other.
`expanded` is a boolean value and defaults to `false` if no value is present.

Returns: nothing
*/
setProp dvTree pTreeA
  put pTreeA into sTreeA
  _buildRowToNodeLookup
  put false into sRebuildLookupTable
  lock screen
  ResetView
  RenderView
  unlock screen
end dvTree


/**
Summary: Returns the internal tree array.

Returns: Array
*/
getProp dvTree
  return sTreeA
end dvTree


/**
Summary: Build lookup tables so that `NumberOfRows` can return correct value.

Returns: nothing
*/
command RenderView
  if sRebuildLookupTable then
    _buildRowToNodeLookup
    put false into sRebuildLookupTable
  end if
  pass RenderView
end RenderView


command DataForRow pRow, @rData, @rTemplateStyle
  local tNodeA, tIndexA, tKey

  put sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] into tIndexA

  # id, type, expanded, is leaf, + any custom keys
  repeat for each key tKey in sTreeA[ tIndexA ]
    if tKey is "children" then next repeat
    put sTreeA[ tIndexA ][tKey] into tNodeA[tKey]
  end repeat

  put _nodeLevel(tIndexA) into tNodeA["level"]
  put the number of elements of sTreeA[ tIndexA ]["children"] into tNodeA["child count"]

  dispatch "DataForNode" with tNodeA, pRow, rData, rTemplateStyle
end DataForRow


function NumberOfRows
  return the number of elements of sRowNodeIdLookupA
end NumberOfRows


function CacheKeyForRow pRow
  return sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["id"]
end CacheKeyForRow


/**
Summary: Refreshes the view after toggling or showing nodes.

Description:
When calling handlers that toggle the expanded state of a node(s) the UI
is not updated. This allows you to update multiple nodes and redraw all at
once. Call this handler when you are ready to redraw the view.

Returns: nothing
*/
command RefreshView
  _refreshView
  return empty
end RefreshView


/**
Summary: Expands all rows in the tree.

Description:
Call `RefreshView` to redraw the view.

Returns: nothing
*/
command ExpandAllNodes
  _setExpandedInTreeBranch sTreeA, empty, true
  put true into sRebuildLookupTable
  _refreshView
end ExpandAllNodes


/**
Summary: Contracts all rows in the tree.

Description:
Call `RefreshView` to redraw the view.

Returns: nothing
*/
command CollapseAllNodes
  _setExpandedInTreeBranch sTreeA, empty, false
  put true into sRebuildLookupTable
  _refreshView
end CollapseAllNodes


/**
Summary: Sets the expanded state of a row.

Parameters:
pRow: The row to toggle.
pLevelsDown: How many levels to toggle. Empty or 0 only toggles pRow. -1 toggles all. Positive number affects that many levels down.
pExpandedState: Pass in a true/false to force a setting.
pRefreshView: Pass in false to keep the view from being refreshed.

Description:
By default the DataView will be redrawn after calling this handler and the newly displayed
children nodes will be scrolled into view. If you pass in `false` for `pRefreshView`
then call `RefreshView` to redraw the view.

Returns: Nothing
*/
command SetRowIsExpanded pRow, pLevelsDown, pExpandedState, pRefreshView
  local tNodeIndexA
  local tCurrentLevel

  if pRow < 1 then throw "invalid row:" && pRow

  put pRefreshView is not false into pRefreshView

  put sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] into tNodeIndexA
  if sTreeA[tNodeIndexA]["is leaf"] then throw "cannot expand a leaf node"

  if pLevelsDown is empty then
    put 0 into pLevelsDown
  else if pLevelsDown < 0 then
    put -1 into pLevelsDown
  end if

  # Toggle
  _setNodeExpandedState tNodeIndexA, pExpandedState

  # Affect children
  if pLevelsDown is not 0 then
    put 0 into tCurrentLevel
    _setNodeAncestorExpandedState tNodeIndexA, sTreeA[tNodeIndexA]["expanded"], \
          pLevelsDown, tCurrentLevel
  end if

  if pRefreshView then
    _refreshView
  end if

  return empty
end SetRowIsExpanded


/**
Summary: Sets the expanded state of a node.

Parameters:
pNode: The node `id` or the node index array.
pLevelsDown: How many levels to toggle. Empty or 0 only toggles pRow. -1 toggles all. Positive number affects that many levels down.
pExpandedState: Pass in a true/false to force a setting.
pRefreshView: Pass in `false` to keep the view from being refreshed.

Description:
Expands the target node, expanding ancestors if need be in order to show the
target node.

See `SetRowIsExpanded` for more information.

Returns: empty
*/
command SetNodeIsExpanded pNode, pLevelsDown, pExpandedState, pRefreshView
  if pNode is not an array then put _findNodeOfId(pNode, true) into pNode

  # Make sure node is visible
  _showNode pNode

  if sRebuildLookupTable then
    _buildRowToNodeLookup
    put false into sRebuildLookupTable
  end if

  SetRowIsExpanded _rowOfNode(pNode), pLevelsDown, pExpandedState, pRefreshView
  return empty
end SetNodeIsExpanded


/**
Summary: Toggles the expanded state of a row.

Parameters:
pRow: The row to toggle.
pLevelsDown: How many levels to toggle. Empty or 0 only toggles pRow. -1 toggles all. Positive number affects that many levels down.
pRefreshView: Pass in false to keep the view from being refreshed.

Description:
See `SetRowIsExpanded`.

Returns: Nothing
*/
command ToggleRowIsExpanded pRow, pLevelsDown, pRefreshView
  local tNodeIndexA, tExpandedState

  put sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] into tNodeIndexA
  put not sTreeA[tNodeIndexA]["expanded"] into tExpandedState

  SetRowIsExpanded pRow, pLevelsDown, tExpandedState, pRefreshView
  return the result
end ToggleRowIsExpanded


/**
Summary: Toggles the expanded state of a node.

Parameters:
pNode: The node `id` or the node index array.
pLevelsDown: How many levels to toggle. Empty or 0 only toggles pRow. -1 toggles all. Positive number affects that many levels down.
pRefreshView: Pass in false to keep the view from being refreshed.

Description:
See `SetRowIsExpanded`.

Returns: empty
*/
command ToggleNodeIsExpanded pNode, pLevelsDown, pRefreshView
  local tExpandedState

  if pNode is not an array then put _findNodeOfId(pNode, true) into pNode

  put not sTreeA[pNode]["expanded"] into tExpandedState
  SetNodeIsExpanded pNode, pLevelsDown, tExpandedState, pRefreshView
  return empty
end ToggleNodeIsExpanded


/**
Summary: Expands any tree nodes necessary so that the node can be seen.

Parameters:
pNode: The node `id` or the node index array.
pRefreshView: Pass in false to keep the view from being refreshed.

Description:
By default the DataView will be redrawn after calling this handler and the node will
be scrolled into view. If you pass in `false` for `pRefreshView`
then call `RefreshView` to redraw the view and `ScrollRowIntoView` to scroll
the row into view.

Returns: empty
*/
command ShowNode pNode, pRefreshView
  if pNode is not an array then put sNodeIdNodeLookupA[pNode] into pNode
  _showNode pNode

  if pRefreshView then
    lock screen
    _refreshView
    ScrollRowIntoView _rowOfNode(pNode)
    unlock screen
  end if

  return empty
end ShowNode


/**
Summary: Scrolls a row and it's descendants into view.

Parameters:
pRow: The target row.

Description:
When expanding a row it may be desirable to scroll the newly exposed children
into view. This handler will scroll the descendants into view without pushing
pRow off the top.

Returns: nothing
*/
command ScrollRowDescendantsIntoView pRow
  local tDescendantsA, tRect, tHeight

  put the dvRectOfRow[pRow] of me into tRect
  add item 4 of tRect - item 2 of tRect to tHeight

  put _descendantElements(sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]], true) into tDescendantsA
  if tDescendantsA is an array then
    repeat with i = 1 to the number of elements of tDescendantsA
      put the dvRectOfRow[ _rowOfNode(tDescendantsA[i]) ] of me into tRect
      add item 4 of tRect - item 2 of tRect to tHeight
    end repeat
  end if

  if tHeight > the viewProp["content window height"] of me then
    # Descendants are too tall. Scroll anchor row to top.
    ScrollRowIntoView pRow, "top"
  else
    # All descendants fit into view. Scroll last one to bottom.
    local tLastRow
    if tDescendantsA is an array then
      put _rowOfNode(tDescendantsA[the number of elements of tDescendantsA]) into tLastRow
    else
      put pRow into tLastRow
    end if
    ScrollRowIntoView tLastRow, "bottom"
  end if
end ScrollRowDescendantsIntoView


/**
Summary: See ScrollRowDescendantsIntoView/

Returns: nothing
*/
command ScrollNodeDescendantsIntoView pNode
  ScrollRowDescendantsIntoView _rowOfNode(pNode)
end ScrollNodeDescendantsIntoView


/**
Summary: Finds a node by `id` and returns the index array pointing to a node in the tree.

Parameters:
pNodeId: The `id` of the node.

Description:
The index array that is returned by this function can be used in other DataView Tree
handlers. Index array can be used by the LiveCode engine to find nested keys in a
LiveCode array.

An index array is a numerically indexed array that represents the keys pointing
to a specific key in a nested array. For a key that is not nested the index array
would have a single key. For a key that is nested three levels deep the index
array would have three keys.

Assume the following array:

```
tPersonA["name"]
tPersonA["children"]
tPersonA["children"][1]["name"]
tPersonA["children"][2]["name"]
tPersonA["children"][3]["name"]
```

The index array for the third child would be as follows:

```
put "children" into tIndexA[1]
put 3 into tIndexA[2]
```

To get the name of the third child you would use the following syntax:

```
put tPersonA[tIndexA]["name"] into tChildName
```

Returns: Index array
*/
getProp dvNodeOfId[pNodeId]
  return _findNodeOfId(pNodeId, false)
end dvNodeOfId


/**
Summary: Returns the row assigned to a node.

Parameters:
pNodeId: The node id to search for.

Description:
If no row is associated with the id passed in then 0 is returned.
A valid id will not have a row if it is the descendant of an
ancestor that is not expanded.

Returns: Integer
*/
getProp dvRowOfId[pNodeId]
  return _rowOfNode(pNodeId)
end dvRowOfId


/**
Summary: Returns the node index array of the node associated with a row.

Returns: Array
*/
getProp dvRowNode[pRow]
  return sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]]
end dvRowNode


/**
Summary: Returns the `id` of the row's node.

Parameters:
pRow: The target row

Returns: Mixed
*/
getProp dvRowId[pRow]
  return sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["id"]
end dvRowId


/**
Summary: Sets the `type` of a row.

Parameters:
pRow: The target row.
pType: The type.

Description:
Setting this property will not refresh the DataView.
*/
setProp dvRowType[pRow] pType
  put pType into sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["type"]
end dvRowType


/**
Summary: Returns the `type` of the row's node.

Parameters:
pRow: The target row

Returns: Mixed
*/
getProp dvRowType[pRow]
  return sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["type"]
end dvRowType


/**
Summary: Sets the `type` of a node.

Parameters:
pNodeId: The target node id.
pType: The type.

Description:
Setting this property will not refresh the DataView.
*/
setProp dvNodeType[pNodeId] pType
  put _findNodeOfId(pNodeId, true) into pNodeId
  put pType into sTreeA[ pNodeId ]["type"]
end dvNodeType


/**
Summary: Returns the `type` of the node.

Parameters:
pNode: The target node id

Returns: Value
*/
getProp dvNodeType[pNodeId]
  return _getNodeProperty(pNodeId, "type")
end dvNodeType


/**
Summary: Returns the `expanded` property of the row's node.

Parameters:
pRow: The target row

Returns: Boolean
*/
getProp dvRowIsExpanded[pRow]
  return sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["expanded"]
end dvRowIsExpanded


/**
Summary: Expands the target row.

Parameters:
pRow: The target row
pIsExpanded: Boolean value.

Description:
For more options when expanding a row see `SetRowIsExpanded`.
*/
setProp dvRowIsExpanded[pRow] pIsExpanded
  SetRowIsExpanded pRow, 0, pIsExpanded is true, true
end dvRowIsExpanded


/**
Summary: Returns the `expanded` property of the node.

Parameters:
pNode: The target node id.

Returns: Boolean
*/
getProp dvNodeIsExpanded[pNodeId]
  return _getNodeProperty(pNodeId, "expanded")
end dvNodeIsExpanded


/**
Summary: Expands the target node.

Parameters:
pRow: The target row
pIsExpanded: Boolean value.

Description:
Setting this property will not refresh the DataView.

For more options when expanding a row see `SetNodeIsExpanded`.
*/
setProp dvNodeIsExpanded[pNodeId] pIsExpanded
  SetNodeIsExpanded pNodeId, 0, pIsExpanded is true, true
end dvNodeIsExpanded


/**
Summary: Sets the `is leaf` of a row.

Parameters:
pRow: The target row.
pIsLeaf: Boolean.

Description:
Setting this property will not refresh the DataView.
*/
setProp dvRowIsLeaf[pRow] pIsLeaf
  put pIsLeaf is true into sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["is leaf"]
end dvRowIsLeaf


/**
Summary: Returns the `is leaf` property of the row's node.

Parameters:
pRow: The target row

Returns: Boolean
*/
getProp dvRowIsLeaf[pRow]
  return sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["is leaf"]
end dvRowIsLeaf


/**
Summary: Sets the `is leaf` of a node.

Parameters:
pNodeId: The target node id.
pIsLeaf: Boolean.

Description:
Setting this property will not refresh the DataView.
*/
setProp dvNodeIsLeaf[pNodeId] pIsLeaf
  put _findNodeOfId(pNodeId, true) into pNodeId
  put pIsLeaf is true into sTreeA[ pNodeId ]["is leaf"]
end dvNodeIsLeaf


/**
Summary: Returns the `is leaf` property of the node.

Parameters:
pNode: The target node id.

Returns: Boolean
*/
getProp dvNodeIsLeaf[pNodeId]
  return _getNodeProperty(pNodeId, "is leaf")
end dvNodeIsLeaf


/**
Summary: Returns the number of children that a row has.

Returns: Integer
*/
getProp dvRowChildCount[pRow]
  if not sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["is leaf"] then
    return the number of elements of sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["children"]
  else
    return 0
  end if
end dvRowChildCount


/**
Summary: Sets the child nodes of a row.

Parameters:
pRow: The target row.
pNodesA: A numerically indexed array of child node arrays.

Returns: nothing
*/
setProp dvRowChildren[pRow] pNodesA
  put pNodesA into sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["children"]
  if sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["expanded"] then
    put true into sRebuildLookupTable
  end if
end dvRowChildren


/**
Summary: Returns a numerically indexed array of the index arrays of the child nodes of a row.

Parameters:
pRow: The target row.

Returns: Array
*/
getProp dvRowChildren[pRow]
  return sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["children"]
end dvRowChildren


/**
Summary: Sets the child nodes of a node.

Parameters:
pRow: The target node id.
pNodesA: A numerically indexed array of child node arrays.

Description:
Setting this property will not refresh the DataView.
*/
setProp dvNodeChildren[pNodeId] pNodesA
  put _findNodeOfId(pNodeId, true) into pNodeId

  if sTreeA[ pNodeId ]["is leaf"] then throw "cannot set children property on a leaf node"

  put pNodesA into sTreeA[ pNodeId ]["children"]
  if sTreeA[ pNodeId ]["expanded"] then
    put true into sRebuildLookupTable
  end if
end dvNodeChildren


/**
Summary: Returns a numerically indexed array of the index arrays of the child nodes of a node.

Parameters:
pRow: The target node id.

Returns: Array
*/
getProp dvNodeChildren[pNodeId]
  return _getNodeProperty(pNodeId, "children")
end dvNodeChildren


/**
Summary: Returns the value for a key stored in a row's node array.

Parameters:
pRow: The target row.
pKey: The key.

Description:
This function allow you to get the value of a key in the node array that doesn't
have a built-in getProp handler.

Returns: Mixed
*/
function GetValueForKeyInRow pRow, pKey
  return GetValueForKeyInNode(sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]], pKey)
end GetValueForKeyInRow


/**
Summary: Sets the value of a custom key stored in a row's node array.

Parameters:
pRow: The target row.
pKey: The custom key.
pValue: The value to assign to the key.

Description:
This function allow you to set the value of a key in the node array that is
not one of the built-in properties `id`, `type`, `expanded`, `is leaf`, `children`,
`level`, and `child count`.

Returns: nothing
*/
command SetValueForKeyInRow pRow, pKey, pValue
  SetValueForKeyInNode sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]], pKey, pValue
  return empty
end SetValueForKeyInRow


/**
Summary: Returns the key value for a node array.

Parameters:
pNodeId: The node id or index array.
pKey: The key.

Description:
See `GetValueForKeyInRow`.

Returns: Mixed
*/
function GetValueForKeyInNode pNodeId, pKey
  if pNodeId is not an array then put _findNodeOfId(pNodeId, true) into pNodeId
  return sTreeA[ pNodeId ][pKey]
end GetValueForKeyInNode


/**
Summary: Sets the value of a custom key stored in a rows node array.

Parameters:
pNodeId: The node id or index array.
pKey: The custom key.
pValue: The value to assign to the key.

Description:
See `SetValueForKeyInRow`.

Returns: nothing
*/
command SetValueForKeyInNode pNodeId, pKey, pValue
  if pKey is among the items of kBuiltInProperties then throw pKey && "is not a custom key"
  if pNodeId is not an array then put _findNodeOfId(pNodeId, true) into pNodeId
  put pValue into sTreeA[ pNodeId ][pKey]
  return empty
end SetValueForKeyInNode


/**
Summary: Returns the number of children that a node has.

Returns: Integer
*/
getProp dvNodeChildCount[pNodeId]
  put _findNodeOfId(pNodeId, true) into pNodeId
  if not sTreeA[pNodeId]["is leaf"] then
    return the number of elements of sTreeA[pNodeId]["children"]
  else
    return 0
  end if
end dvNodeChildCount


/**
Summary: Returns the row numbers of a row's children.

Returns: List
*/
getProp dvRowChildRows[pRow]
  local tList
  repeat with i = pRow + 1 to pRow + the number of elements of sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ]["children"]
    put i & "," after tList
  end repeat
  delete the last char of tList
  return tList
end dvRowChildRows


/**
Summary: Returns an integer representing the position of `pRow` amongst it's siblings.

Parameters:
pRow: The target row.

Description:
If pRow is the third child of it's parent then this property would return `3`.

Returns: Integer
*/
getProp dvRowPositionAmongSiblings[pRow]
  local tNodeIndexA

  # The numerically index is sibling position.
  put sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] into tNodeIndexA
  return tNodeIndexA[the number of elements of tNodeIndexA]
end dvRowPositionAmongSiblings


/**
Summary: Returns the tree level of a node.

Parameters:
pNode: The node `id`.

Returns: Integer
*/
getProp dvNodeLevel[pNodeId]
  put _findNodeOfId(pNodeId, true) into pNodeId
  return _nodeLevel(pNodeId)
end dvNodeLevel


/**
Summary: Returns the tree level of a row.

Parameters:
pRow: The row number.

Returns: Integer
*/
getProp dvRowLevel[pRow]
  return _nodeLevel( sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] )
end dvRowLevel


/**
Summary: Returns the row number of a rows parent.

Parameters:
pRow: The target row number.

Description:
If the row does not have a parent then 0 is returned.

Returns: Integer
*/
getProp dvRowParentRow[pRow]
  local pNodeIndexA
  put _parentNodeIndex( sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] ) into pNodeIndexA
  if pNodeIndexA is an array then
    return _rowOfNode(pNodeIndexA)
  else
    return 0
  end if
end dvRowParentRow


/**
Summary: Returns a node's parent node id.

Parameters:
pNode: The node `id`.

Description:
If the node does not have a parent then empty is returned.

Returns: Integer
*/
getProp dvNodeParentNode[pNodeId]
  local tNodeIndexA
  put _findNodeOfId(pNodeId, true) into pNodeId
  put _parentNodeIndex(pNodeId) into tNodeIndexA

  if tNodeIndexA is an array then
    return sTreeA[tNodeIndexA]["id"]
  else
    return empty
  end if
end dvNodeParentNode


/**
Summary: Returns index arrays pointing to ancestors of a row.

Parameters:
pRow: The row to get ancestor nodes for.

Returns: Numerically indexed array of index arrays
*/
getProp dvRowAncestorNodes[pRow]
  return _ancestorElements( sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]] )
end dvRowAncestorNodes


/**
Summary: Returns index arrays pointing to ancestors of a node.

Parameters:
pNode: The node `id`.

Returns: Numerically indexed array of index arrays
*/
getProp dvNodeAncestorNodes[pNodeId]
  put _findNodeOfId(pNodeId, true) into pNodeId
  return _ancestorElements(pNodeId)
end dvNodeAncestorNodes


/**
Summary: Returns the node keys of the descendants of a row.

Parameters:
pRow: The row to get ancestor nodes for.

Returns: Numerically indexed array of index arrays
*/
getProp dvRowDescendantNodes[pRow]
  return _descendantElements(sNodeIdNodeLookupA[sRowNodeIdLookupA[pRow]], false)
end dvRowDescendantNodes


/**
Summary: Returns index arrays that point to the descendants of a node.

Parameters:
pNode: The node `id`.
pOnlyVisible: Pass in true to only return the visible descendant elements. Default is `false`.

Returns: Numerically indexed array of index arrays
*/
getProp dvNodeDescendantNodes[pNodeId]
  put _findNodeOfId(pNodeId, true) into pNodeId
  return _descendantElements(pNodeId, false)
end dvNodeDescendantNodes


/**
Summary: Returns the `id` property of the selected row(s).

Description:
If not rows are selected then empty is returned.

Returns: Comma-delimited list of integers
*/
getProp dvHilitedIds
  local tRow, tRows, tIds

  put the dvHilitedRow of me into tRows

  repeat for each item tRow in tRows
    if sRowNodeIdLookupA[tRow] is not empty then
      put sRowNodeIdLookupA[tRow] & "," after tIds
    end if
  end repeat
  delete the last char of tIds
  return tIds
end dvHilitedIds


getProp dvHilitedId
  return the dvHilitedIds of me
end dvHilitedId


/**
Summary: Sets the selected row based on the `id` property of a row(s).

Parameters:
pForceScroll: Passed along to `dvHilitedRow` in the DataView behavior.
pIds: Comma-delimited list of ids to hilite.

Description:
If any ids in `pIds` is not currently associated with a row then the tree
will be expanded to show it.

Note that if your ids have a "," in them then this property won't work correctly.
*/
setProp dvHilitedIds[pForceScroll] pIds
  local tId, tNodeIndexA, tRows

  repeat for each item tId in pIds
    if sNodeIdRowLookupA[tId] is empty then
      put _findNodeOfId(tId, false) into tNodeIndexA
      if tNodeIndexA is an array then
        _showNode tNodeIndexA
      end if
    end if
  end repeat

  if sRebuildLookupTable then
    _refreshView
  end if

  repeat for each item tId in pIds
    if sNodeIdRowLookupA[tId] is not empty then
      put sNodeIdRowLookupA[tId] & "," after tRows
    end if
  end repeat
  delete the last char of tRows

  set the dvHilitedRow[pForceScroll] of me to tRows
end dvHilitedIds


setProp dvHilitedId[pForceScroll] pIds
  set the dvHilitedIds[pForceScroll] of me to pIds
end dvHilitedId


/**
Summary: Returns the `id` property of the selected row(s).

Description:
If not rows are selected then empty is returned.

Returns: Comma-delimited list of integers
*/
getProp dvHilitedData
  local tRow, tRows, tIds

  put the dvHilitedRow of me into tRows

  if the number of items of tRows is 1 then
    return sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[tRows]] ]
  else
    local tDataA, i
    repeat for each item tRow in tRows
      add 1 to i
      put sTreeA[ sNodeIdNodeLookupA[sRowNodeIdLookupA[tRow]] ] into tDataA[i]
    end repeat
    return tDataA
  end if
end dvHilitedData


/**
Summary: Builds the lookup table used to match nodes to rows.

Returns: nothing
*/
private command _buildRowToNodeLookup
  local tIndex

  put 0 into tIndex
  put empty into sRowNodeIdLookupA
  put empty into sNodeIdNodeLookupA
  put empty into sNodeIdRowLookupA

  _addBranchToRowToNodeLookup sTreeA, empty, tIndex

  return empty
end _buildRowToNodeLookup


/**
Summary: Adds a branch of sTreeA to the lookup table.

Returns: nothing
*/
private command _addBranchToRowToNodeLookup pTreeBranchA, pIndexA, @xRow
  local tLookupIndex, tIndex, tNodeA

  put the number of elements of pIndexA + 1 into tLookupIndex

  repeat for each element tNodeA in pTreeBranchA
    add 1 to tIndex
    add 1 to xRow

    if sNodeIdNodeLookupA[tNodeA["id"]] is an array then
      throw "duplicate node id in tree:" && tNodeA["id"]
    end if

    put tIndex into pIndexA[tLookupIndex]

    put pIndexA into sNodeIdNodeLookupA[tNodeA["id"]]
    put tNodeA["id"] into sRowNodeIdLookupA[xRow]
    put xRow into sNodeIdRowLookupA[tNodeA["id"]]

    if tNodeA["expanded"] is empty then put false into tNodeA["expanded"]

    if not tNodeA["is leaf"] and tNodeA["expanded"] and the number of elements of tNodeA["children"] > 0 then
      put "children" into pIndexA[tLookupIndex+1]
      _addBranchToRowToNodeLookup tNodeA["children"], pIndexA, xRow
      delete local pIndexA[tLookupIndex+1]
    end if
  end repeat

  return empty
end _addBranchToRowToNodeLookup


private command _refreshView pTargetRow
  local i, tSelNodesA

  # store selected elements
  repeat for each item tRow in the dvHilitedRows of me
    add 1 to i
    put sNodeIdNodeLookupA[sRowNodeIdLookupA[tRow]] into tSelNodesA[i]
  end repeat

  lock screen
  RenderView

  # update selected rows
  # rows may no longer be available because they are contracted
  if tSelNodesA is an array then
    local tSelRows

    repeat with i = 1 to the number of elements of tSelNodesA
      put _rowOfNode(tSelNodesA[i]) into tRow
      if tRow > 0 then
        put tRow & "," after tSelRows
      end if
    end repeat
    delete the last char of tSelRows

    if tSelRows is empty then put pTargetRow into tSelRows
    set the dvHilitedRows of me to tSelRows
  end if

  unlock screen
end _refreshView


/**
Summary: Recursively sets the `expanded` key of all nodes in the tree.

Parameters:
pTreeBranchA: The array representing a branch in the tree.
pIndexA: The index array that points to the branch of the tree.
pBoolean: `true` or `false`.

Returns: nothing
*/
private command _setExpandedInTreeBranch pTreeBranchA, pIndexA, pBoolean
  local tIndex, i

  put the number of elements of pIndexA into tIndex
  add 1 to tIndex

  repeat with i = 1 to the number of elements of pTreeBranchA
    put i into pIndexA[tIndex]

    if sTreeA[pIndexA]["is leaf"] then next repeat

    put pBoolean into sTreeA[pIndexA]["expanded"]

    if sTreeA[pIndexA]["children"] is not empty then
      put "children" into pIndexA[tIndex+1]
      _setExpandedInTreeBranch sTreeA[pIndexA]["children"], pIndexA, pBoolean
      delete variable pIndexA[tIndex+1]
    end if
  end repeat
end _setExpandedInTreeBranch


/**
Summary: Returns the row associated with a node.

Parameters:
pNodeIndexA: Node index array.

Description:
This will return 0 if no row is found.

Returns: Integer
*/
private function _rowOfNode pNode
  if pNode is an array then
    put sTreeA[pNode]["id"] into pNode
  end if

  return max(0, sNodeIdRowLookupA[pNode])
end _rowOfNode


private function _getNodeProperty pNodeId, pProperty
  put _findNodeOfId(pNodeId, true) into pNodeId
  return sTreeA[pNodeId][pProperty]
end _getNodeProperty


/**
Summary: Returns the level of a node in the tree.

Returns: Integer
*/
private function _nodeLevel pNodeIndexA
  local tLevel, tKey

  repeat for each key tKey in pNodeIndexA
    if pNodeIndexA[tKey] is an integer then
      add 1 to tLevel
    end if
  end repeat

  return tLevel
end _nodeLevel


private function _findNodeOfId pNodeId, pWithValidation
  local tFoundIndexA

  put _searchBranchForNodeId(sTreeA, empty, pNodeId) into tFoundIndexA
  if tFoundIndexA is not an array then
    if pWithValidation then
      throw "node id not found:" && pNodeId
    else
      return empty
    end if
  else
    return tFoundIndexA
  end if
end _findNodeOfId


private function _searchBranchForNodeId pTreeBranchA, pIndexA, pNodeId
  local tIndex, tFoundIndexA, tNodeA, i

  if sNodeIdNodeLookupA[pNodeId] is an array then
    return sNodeIdNodeLookupA[pNodeId]
  else
    put the number of elements of pIndexA + 1 into tIndex

    repeat for each element tNodeA in pTreeBranchA
      add 1 to i
      put i into pIndexA[tIndex]

      if tNodeA["id"] is pNodeId then
        put pIndexA into sNodeIdNodeLookupA[pNodeId]
        return pIndexA
      end if

      if the number of elements of tNodeA["children"] > 0 then
        put "children" into pIndexA[tIndex+1]
        put _searchBranchForNodeId(tNodeA["children"], pIndexA, pNodeId) into tFoundIndexA
        delete local pIndexA[tIndex+1]

        if tFoundIndexA is an array then
          put tFoundIndexA into sNodeIdNodeLookupA[pNodeId]
          return tFoundIndexA
        end if
      end if
    end repeat
  end if

  return empty
end _searchBranchForNodeId


/**
Summary: Sets the expanded state for a node.

Parameters:
pNodeIndexA: The node index array.
pBoolean: The value to assign to the expanded state. Leave empty to toggle.

Returns: empty
*/
private command _setNodeExpandedState pNodeIndexA, pBoolean
  if pBoolean is empty then
    put not sTreeA[pNodeIndexA]["expanded"] into pBoolean
  else
    put pBoolean is true into pBoolean
  end if

  if sTreeA[pNodeIndexA]["expanded"] is not pBoolean then
    if sTreeA[pNodeIndexA]["is leaf"] is not true then
      put pBoolean into sTreeA[pNodeIndexA]["expanded"]
      put true into sRebuildLookupTable
    end if
  end if

  return empty
end _setNodeExpandedState


/**
Summary: Expands any tree nodes necessary so that the node can be seen.

Parameters:
pNodeIndexA: The node index array.

Returns: empty
*/
private command _showNode pNodeIndexA
  if pNodeIndexA is not an array then throw "invalid node index array"

  repeat while pNodeIndexA is an array
    if not sTreeA[pNodeIndexA]["is leaf"] and not sTreeA[pNodeIndexA]["expanded"] then
      _setNodeExpandedState pNodeIndexA, true
    end if
    put _parentNodeIndex(pNodeIndexA) into pNodeIndexA
  end repeat

  return empty
end _showNode


/**
Summary: Recursive helper command for expanding nodes.

Parameters:
pNodeIndexA: The node index array.
pExpandedState: True or false.
pLevelsDown: The number of levels down to expand. Leave empty to expand all children.
@rCurrentLevel: The current level that is being expanded. When this matches pLevelsDown or the last child is expanded then recursion stops.

Returns: empty
*/
private command _setNodeAncestorExpandedState pNodeIndexA, pExpandedState, pLevelsDown, @xCurrentLevel
  local tCurrentLevel

  put pExpandedState is true into pExpandedState

  add 1 to tCurrentLevel
  put xCurrentLevel into tCurrentLevel

  local tIndex
  put the number of elements of pNodeIndexA + 1 into tIndex
  put "children" into pNodeIndexA[tIndex]
  add 1 to tIndex

  repeat with i = 1 to the number of elements of sTreeA[pNodeIndexA]["children"]
    put i into pNodeIndexA[tIndex]
    if sTreeA[pNodeIndexA]["expanded"] is not pExpandedState then
      _setNodeExpandedState pNodeIndexA, pExpandedState
    end if

    if tCurrentLevel is not pLevelsDown then
      _setNodeAncestorExpandedState pNodeIndexA, pExpandedState, pLevelsDown, xCurrentLevel
      put tCurrentLevel into xCurrentLevel # reset for next child in loop.
    end if
  end repeat

  return empty
end _setNodeAncestorExpandedState


/**
Summary: Returns index arrays pointing to the descendants of a node.

Parameters:
pNodeIndexA: The node index array.
pOnlyVisible: Only get the visible ancestor ids.

Returns: Numerically indexed array of index arrays
*/
private function _descendantElements pNodeIndexA, pOnlyVisible
  local tDescendantsA, tIndex, tChildIndexA
  local tDescIndex

  put pOnlyVisible is true into pOnlyVisible

  if not pOnlyVisible OR \
        (pOnlyVisible AND sTreeA[pNodeIndexA]["expanded"]) then

    local tTempDescendantsA

    put pNodeIndexA into tChildIndexA
    put the number of elements of tChildIndexA + 1 into tIndex
    put "children" into tChildIndexA[tIndex]
    add 1 to tIndex

    repeat with i = 1 to the number of elements of sTreeA[pNodeIndexA]["children"]
      put i into tChildIndexA[tIndex]
      add 1 to tDescIndex
      put tChildIndexA into tDescendantsA[tDescIndex]

      put _descendantElements(tChildIndexA, pOnlyVisible) into tTempDescendantsA

      repeat with j = 1 to the number of elements of tTempDescendantsA
        add 1 to tDescIndex
        put tTempDescendantsA[j] into tDescendantsA[tDescIndex]
      end repeat
    end repeat
  end if

  return tDescendantsA
end _descendantElements


/**
Summary: Returns the index array for the parent of an index array that points to a node.
*/
private function _parentNodeIndex pNodeIndexA
  local tCount

  put the number of elements of pNodeIndexA into tCount
  if pNodeIndexA[tCount - 1] is "children" then
    delete variable pNodeIndexA[tCount]
    delete variable pNodeIndexA[tCount-1]
    return pNodeIndexA
  else
    return empty
  end if
end _parentNodeIndex


/**
Summary: Returns index arrays pointing to ancestors of a node.

Parameters:
pNodeIndexA: The node index array.

Returns: Numerically indexed array of index arrays
*/
private function _ancestorElements pNodeIndexA
  local tAncestorsA, tIndexCount, i

  put the number of elements of pNodeIndexA into tIndexCount

  repeat forever
    if pNodeIndexA[tIndexCount-1] is "children" then
      delete variable pNodeIndexA[tIndexCount]
      delete variable pNodeIndexA[tIndexCount]

      add 1 to i
      put pNodeIndexA into tAncestorsA[i]
    end if
  end repeat

  return tAncestorsA
end _ancestorElements
