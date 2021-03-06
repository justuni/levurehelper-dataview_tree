# DataView Tree Helper

The DataView Tree helper adds support for working with tree data structures to a [DataView](https://github.com/trevordevore/levurehelper-dataview). This is done by adding a new behavior to the DataView that is a parent behavior of the standard DataView behavior. The new behavior adds an API for setting a tree structure containing nodes, accessing properties of the nodes and associated rows, toggling the expanded state of nodes.

The helper does not provide support for creating UI elements such as an expand/contract widget. It only provides an API that your UI elements can call.

Note that this helper requires the [DataView helper](https://github.com/trevordevore/levurehelper-dataview).

## Demo

The DataView Demo application includes an example of using this helper:

https://github.com/trevordevore/dataview_demo

## Usage

In order to use the DataView Tree helper you must do two things:

1. Assign the behavior of your DataView control to `stack "DataView Tree Behavior"`. If you are already using a custom behavior with your DataView then assign the behavior __of your custom behavior__ to `stack "DataView Tree Behavior"` 
2. Create an array in the specified format and assign it to the `dvTree` property of the DataView.
3. Create one or more templates to display types of nodes in the tree.
4. Implement the `DataForNode` message in order to feed the tree data as needed.

## Creating a DataView Tree

The DataView helper includes a command which can create DataView Tree group controls in the LiveCode IDE:

- `dvtIdecreateDataViewTreeControlUsingDialog pTargetCard`

`dvtIdecreateDataViewTreeControlUsingDialog` will call `dvIdeCreateDataViewControlUsingDialog` (see [DataView](https://github.com/trevordevore/levurehelper-dataview readme)) with some options customized for the DataView Tree.

## The tree array

The DataView Tree uses an array that represents a tree. This array has the least amount of data needed in order for the DataView Tree to work. The actual data that is displayed in the UI will be provided by some other data source. This data is supplied to the DataView Tree by way of the `DataForNode` message.

The array assigned to the `dvTree` property is a numerically indexed array of node arrays (arrays nested within an array). Each node array has the following keys:

1. `id`: Uniquely identifies the node in the tree. This also links the node to a record in your data source.
2. `type`: Identifies the type of the node. This property can help you choose which row template to use for a given node.
3. `expanded`: Boolean value specifying whether or not the node is expanded. Default is `false`.
4. `children`: A numerically indexed array of child nodes.
5. `is leaf`: Boolean value specifying whether or not the node can have children. If `true` then the node cannot have children.

### Sample of keys in a tree array

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
pTreeA[2]["type"]
pTreeA[2]["id"]
pTreeA[2]["expanded"]
pTreeA[2]["is leaf"]
pTreeA[2]["children"]
...
```

## Feeding data to a DataView Tree

A standard DataView sends the `DataForRow` message. Usually there is a 1-1 mapping of data from your data source to the rows displayed in the DataView. In a tree the 1-1 mapping doesn't usually exist as a node can be collapsed which hides it's children in the UI. 

Instead, a DataView Tree sends the `DataForNode` message. Your code must handle the `DataForNode` message in order to feed data to the DataView Tree for display. It looks very similar to the `DataForRow` message that a normal DataView receives but has one additional parameters – `pNodeA`. `pNodeA` contains the following keys:

- `id`
- `type`
- `expanded`
- `is leaf`
- `level`
- `child count`

```
command DataForNode pNodeA, pRow, @rDataA, @rTemplateStyle
  # Use pNodeA["id"] to locate data in your data ource to feed to rData...
  # Assign values to keys in rDataA 
  # Specify the row template style to use in rTemplateStyle
end DataForNode
```

You can use the `pNodeA["id"]` value to locate the data in your data source that should be displayed for the node.

### NumberOfRows() and CacheKeyForRow()
You do not need to worry about defining `NumberOfRows()` or `CacheKeyForRow()`. Both of these functions are defined in the DataView Tree behavior. The behavior returns the node `id` property in the `CacheKeyForRow()` function.

## Accessing node and row properties in the tree

The API includes a number of properties for accessing node or row properties. Most properties have both a row and node version. For example, to check if a row or node is a leaf you can check the `dvRowIsLeaf[pRow]` or `dvNodeIsLeaf[pNodeId]` property.

## Manipulating the tree

A DataView Tree has some additional commands that can be used to manipulate the tree. For example, there is a command for toggling the expanded state of a row (`ToggleRowIsExpanded`) or one for showing a particular node (`ShowNode`).

For example, to toggle the state of the tree you can dispatch `ToggleRowIsExpanded` to a DataView:

```
put 4 into tRow
dispatch "ToggleRowIsExpanded" to group "MyDataView" with tRow
```

## API

- [CollapseAllNodes](#CollapseAllNodes)
- [dvHilitedData](#dvHilitedData)
- [dvHilitedIds](#dvHilitedIds)
- [dvHilitedIds[pForceScroll]](#dvHilitedIds[pForceScroll])
- [dvNodeAncestorNodes[pNodeId]](#dvNodeAncestorNodes[pNodeId])
>
- [dvNodeChildCount[pNodeId]](#dvNodeChildCount[pNodeId])
- [dvNodeChildren[pNodeId]](#dvNodeChildren[pNodeId])
- [dvNodeDescendantNodes[pNodeId]](#dvNodeDescendantNodes[pNodeId])
- [dvNodeIsExpanded[pNodeId]](#dvNodeIsExpanded[pNodeId])
- [dvNodeIsLeaf[pNodeId]](#dvNodeIsLeaf[pNodeId])
>
- [dvNodeLevel[pNodeId]](#dvNodeLevel[pNodeId])
- [dvNodeOfId[pNodeId]](#dvNodeOfId[pNodeId])
- [dvNodeParentNode[pNodeId]](#dvNodeParentNode[pNodeId])
- [dvNodeType[pNodeId]](#dvNodeType[pNodeId])
- [dvRowAncestorNodes[pRow]](#dvRowAncestorNodes[pRow])
>
- [dvRowChildCount[pRow]](#dvRowChildCount[pRow])
- [dvRowChildren[pRow]](#dvRowChildren[pRow])
- [dvRowChildRows[pRow]](#dvRowChildRows[pRow])
- [dvRowDescendantNodes[pRow]](#dvRowDescendantNodes[pRow])
- [dvRowId[pRow]](#dvRowId[pRow])
>
- [dvRowIsExpanded[pRow]](#dvRowIsExpanded[pRow])
- [dvRowIsLeaf[pRow]](#dvRowIsLeaf[pRow])
- [dvRowLevel[pRow]](#dvRowLevel[pRow])
- [dvRowNode[pRow]](#dvRowNode[pRow])
- [dvRowOfId[pNodeId]](#dvRowOfId[pNodeId])
>
- [dvRowParentRow[pRow]](#dvRowParentRow[pRow])
- [dvRowPositionAmongSiblings[pRow]](#dvRowPositionAmongSiblings[pRow])
- [dvRowType[pRow]](#dvRowType[pRow])
- [dvTree](#dvTree)
- [ExpandAllNodes](#ExpandAllNodes)
>
- [GetValueForKeyInNode](#GetValueForKeyInNode)
- [GetValueForKeyInRow](#GetValueForKeyInRow)
- [RefreshView](#RefreshView)
- [RenderView](#RenderView)
- [ScrollNodeDescendantsIntoView](#ScrollNodeDescendantsIntoView)
>
- [ScrollRowDescendantsIntoView](#ScrollRowDescendantsIntoView)
- [SetNodeIsExpanded](#SetNodeIsExpanded)
- [SetRowIsExpanded](#SetRowIsExpanded)
- [SetValueForKeyInNode](#SetValueForKeyInNode)
- [SetValueForKeyInRow](#SetValueForKeyInRow)
>
- [ShowNode](#ShowNode)
- [ToggleNodeIsExpanded](#ToggleNodeIsExpanded)
- [ToggleRowIsExpanded](#ToggleRowIsExpanded)

<br>

## <a name="CollapseAllNodes"></a>CollapseAllNodes

**Type**: command

**Syntax**: `CollapseAllNodes `

**Summary**: Contracts all rows in the tree.

**Returns**: nothing

**Description**:

Call `RefreshView` to redraw the view.

<br>

## <a name="dvHilitedData"></a>dvHilitedData

**Type**: getProp

**Syntax**: `dvHilitedData `

**Summary**: Returns the `id` property of the selected row(s).

**Returns**: Comma-delimited list of integers

**Description**:

If not rows are selected then empty is returned.

<br>

## <a name="dvHilitedIds"></a>dvHilitedIds

**Type**: getProp

**Syntax**: `dvHilitedIds `

**Summary**: Returns the `id` property of the selected row(s).

**Returns**: Comma-delimited list of integers

**Description**:

If not rows are selected then empty is returned.

<br>

## <a name="dvHilitedIds[pForceScroll]"></a>dvHilitedIds[pForceScroll]

**Type**: setProp

**Syntax**: `dvHilitedIds[pForceScroll] <pIds>`

**Summary**: Sets the selected row based on the `id` property of a row(s).

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pIds` |  Comma-delimited list of ids to hilite. |

**Description**:

If any ids in `pIds` is not currently associated with a row then the tree
will be expanded to show it.

Note that if your ids have a "," in them then this property won't work correctly.


<br>

## <a name="dvNodeAncestorNodes[pNodeId]"></a>dvNodeAncestorNodes[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeAncestorNodes[pNodeId] `

**Summary**: Returns index arrays pointing to ancestors of a node.

**Returns**: Numerically indexed array of index arrays

<br>

## <a name="dvNodeChildCount[pNodeId]"></a>dvNodeChildCount[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeChildCount[pNodeId] `

**Summary**: Returns the number of children that a node has.

**Returns**: Integer

<br>

## <a name="dvNodeChildren[pNodeId]"></a>dvNodeChildren[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeChildren[pNodeId] `

**Summary**: Returns a numerically indexed array of the index arrays of the child nodes of a node.

**Returns**: Array

<br>

## <a name="dvNodeDescendantNodes[pNodeId]"></a>dvNodeDescendantNodes[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeDescendantNodes[pNodeId] `

**Summary**: Returns index arrays that point to the descendants of a node.

**Returns**: Numerically indexed array of index arrays

<br>

## <a name="dvNodeIsExpanded[pNodeId]"></a>dvNodeIsExpanded[pNodeId]

**Type**: setProp

**Syntax**: `dvNodeIsExpanded[pNodeId] <pIsExpanded>`

**Summary**: Expands the target node.

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pIsExpanded` |  Boolean value. |

**Description**:

Setting this property will not refresh the DataView.

For more options when expanding a row see `SetNodeIsExpanded`.


<br>

## <a name="dvNodeIsLeaf[pNodeId]"></a>dvNodeIsLeaf[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeIsLeaf[pNodeId] `

**Summary**: Returns the `is leaf` property of the node.

**Returns**: Boolean

<br>

## <a name="dvNodeLevel[pNodeId]"></a>dvNodeLevel[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeLevel[pNodeId] `

**Summary**: Returns the tree level of a node.

**Returns**: Integer

<br>

## <a name="dvNodeOfId[pNodeId]"></a>dvNodeOfId[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeOfId[pNodeId] `

**Summary**: Finds a node by `id` and returns the index array pointing to a node in the tree.

**Returns**: Index array

**Description**:

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

<br>

## <a name="dvNodeParentNode[pNodeId]"></a>dvNodeParentNode[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeParentNode[pNodeId] `

**Summary**: Returns a node's parent node id.

**Returns**: Integer

**Description**:

If the node does not have a parent then empty is returned.

<br>

## <a name="dvNodeType[pNodeId]"></a>dvNodeType[pNodeId]

**Type**: getProp

**Syntax**: `dvNodeType[pNodeId] `

**Summary**: Returns the `type` of the node.

**Returns**: Value

<br>

## <a name="dvRowAncestorNodes[pRow]"></a>dvRowAncestorNodes[pRow]

**Type**: getProp

**Syntax**: `dvRowAncestorNodes[pRow] `

**Summary**: Returns index arrays pointing to ancestors of a row.

**Returns**: Numerically indexed array of index arrays

<br>

## <a name="dvRowChildCount[pRow]"></a>dvRowChildCount[pRow]

**Type**: getProp

**Syntax**: `dvRowChildCount[pRow] `

**Summary**: Returns the number of children that a row has.

**Returns**: Integer

<br>

## <a name="dvRowChildren[pRow]"></a>dvRowChildren[pRow]

**Type**: getProp

**Syntax**: `dvRowChildren[pRow] `

**Summary**: Returns a numerically indexed array of the index arrays of the child nodes of a row.

**Returns**: Array

<br>

## <a name="dvRowChildRows[pRow]"></a>dvRowChildRows[pRow]

**Type**: getProp

**Syntax**: `dvRowChildRows[pRow] `

**Summary**: Returns the row numbers of a row's children.

**Returns**: List

<br>

## <a name="dvRowDescendantNodes[pRow]"></a>dvRowDescendantNodes[pRow]

**Type**: getProp

**Syntax**: `dvRowDescendantNodes[pRow] `

**Summary**: Returns the node keys of the descendants of a row.

**Returns**: Numerically indexed array of index arrays

<br>

## <a name="dvRowId[pRow]"></a>dvRowId[pRow]

**Type**: getProp

**Syntax**: `dvRowId[pRow] `

**Summary**: Returns the `id` of the row's node.

**Returns**: Mixed

<br>

## <a name="dvRowIsExpanded[pRow]"></a>dvRowIsExpanded[pRow]

**Type**: setProp

**Syntax**: `dvRowIsExpanded[pRow] <pIsExpanded>`

**Summary**: Expands the target row.

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pIsExpanded` |  Boolean value. |

**Description**:

For more options when expanding a row see `SetRowIsExpanded`.


<br>

## <a name="dvRowIsLeaf[pRow]"></a>dvRowIsLeaf[pRow]

**Type**: getProp

**Syntax**: `dvRowIsLeaf[pRow] `

**Summary**: Returns the `is leaf` property of the row's node.

**Returns**: Boolean

<br>

## <a name="dvRowLevel[pRow]"></a>dvRowLevel[pRow]

**Type**: getProp

**Syntax**: `dvRowLevel[pRow] `

**Summary**: Returns the tree level of a row.

**Returns**: Integer

<br>

## <a name="dvRowNode[pRow]"></a>dvRowNode[pRow]

**Type**: getProp

**Syntax**: `dvRowNode[pRow] `

**Summary**: Returns the node index array of the node associated with a row.

**Returns**: Array

<br>

## <a name="dvRowOfId[pNodeId]"></a>dvRowOfId[pNodeId]

**Type**: getProp

**Syntax**: `dvRowOfId[pNodeId] `

**Summary**: Returns the row assigned to a node.

**Returns**: Integer

**Description**:

If no row is associated with the id passed in then 0 is returned.
A valid id will not have a row if it is the descendant of an
ancestor that is not expanded.

<br>

## <a name="dvRowParentRow[pRow]"></a>dvRowParentRow[pRow]

**Type**: getProp

**Syntax**: `dvRowParentRow[pRow] `

**Summary**: Returns the row number of a rows parent.

**Returns**: Integer

**Description**:

If the row does not have a parent then 0 is returned.

<br>

## <a name="dvRowPositionAmongSiblings[pRow]"></a>dvRowPositionAmongSiblings[pRow]

**Type**: getProp

**Syntax**: `dvRowPositionAmongSiblings[pRow] `

**Summary**: Returns an integer representing the position of `pRow` amongst it's siblings.

**Returns**: Integer

**Description**:

If pRow is the third child of it's parent then this property would return `3`.

<br>

## <a name="dvRowType[pRow]"></a>dvRowType[pRow]

**Type**: getProp

**Syntax**: `dvRowType[pRow] `

**Summary**: Returns the `type` of the row's node.

**Returns**: Mixed

<br>

## <a name="dvTree"></a>dvTree

**Type**: getProp

**Syntax**: `dvTree `

**Summary**: Returns the internal tree array.

**Returns**: Array

<br>

## <a name="ExpandAllNodes"></a>ExpandAllNodes

**Type**: command

**Syntax**: `ExpandAllNodes `

**Summary**: Expands all rows in the tree.

**Returns**: nothing

**Description**:

Call `RefreshView` to redraw the view.

<br>

## <a name="GetValueForKeyInNode"></a>GetValueForKeyInNode

**Type**: function

**Syntax**: `GetValueForKeyInNode(<pNodeId>,<pKey>)`

**Summary**: Returns the key value for a node array.

**Returns**: Mixed

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pNodeId` |  The node id or index array. |
| `pKey` |  The key. |

**Description**:

See `GetValueForKeyInRow`.

<br>

## <a name="GetValueForKeyInRow"></a>GetValueForKeyInRow

**Type**: function

**Syntax**: `GetValueForKeyInRow(<pRow>,<pKey>)`

**Summary**: Returns the value for a key stored in a row's node array.

**Returns**: Mixed

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pRow` |  The target row. |
| `pKey` |  The key. |

**Description**:

This function allow you to get the value of a key in the node array that doesn't
have a built-in getProp handler.

<br>

## <a name="RefreshView"></a>RefreshView

**Type**: command

**Syntax**: `RefreshView `

**Summary**: Refreshes the view after toggling or showing nodes.

**Returns**: nothing

**Description**:

When calling handlers that toggle the expanded state of a node(s) the UI
is not updated. This allows you to update multiple nodes and redraw all at
once. Call this handler when you are ready to redraw the view.

<br>

## <a name="RenderView"></a>RenderView

**Type**: command

**Syntax**: `RenderView `

**Summary**: Build lookup tables so that `NumberOfRows` can return correct value.

**Returns**: nothing

<br>

## <a name="ScrollNodeDescendantsIntoView"></a>ScrollNodeDescendantsIntoView

**Type**: command

**Syntax**: `ScrollNodeDescendantsIntoView <pNode>`

**Summary**: See ScrollRowDescendantsIntoView/

**Returns**: nothing

<br>

## <a name="ScrollRowDescendantsIntoView"></a>ScrollRowDescendantsIntoView

**Type**: command

**Syntax**: `ScrollRowDescendantsIntoView <pRow>`

**Summary**: Scrolls a row and it's descendants into view.

**Returns**: nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pRow` |  The target row. |

**Description**:

When expanding a row it may be desirable to scroll the newly exposed children
into view. This handler will scroll the descendants into view without pushing
pRow off the top.

<br>

## <a name="SetNodeIsExpanded"></a>SetNodeIsExpanded

**Type**: command

**Syntax**: `SetNodeIsExpanded <pNode>,<pLevelsDown>,<pExpandedState>,<pRefreshView>`

**Summary**: Sets the expanded state of a node.

**Returns**: empty

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pNode` |  The node `id` or the node index array. |
| `pLevelsDown` |  How many levels to toggle. Empty or 0 only toggles pRow. -1 toggles all. Positive number affects that many levels down. |
| `pExpandedState` |  Pass in a true/false to force a setting. |
| `pRefreshView` |  Pass in `false` to keep the view from being refreshed. |

**Description**:

Expands the target node, expanding ancestors if need be in order to show the
target node.

See `SetRowIsExpanded` for more information.

<br>

## <a name="SetRowIsExpanded"></a>SetRowIsExpanded

**Type**: command

**Syntax**: `SetRowIsExpanded <pRow>,<pLevelsDown>,<pExpandedState>,<pRefreshView>`

**Summary**: Sets the expanded state of a row.

**Returns**: Nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pRow` |  The row to toggle. |
| `pLevelsDown` |  How many levels to toggle. Empty or 0 only toggles pRow. -1 toggles all. Positive number affects that many levels down. |
| `pExpandedState` |  Pass in a true/false to force a setting. |
| `pRefreshView` |  Pass in false to keep the view from being refreshed. |

**Description**:

By default the DataView will be redrawn after calling this handler and the newly displayed
children nodes will be scrolled into view. If you pass in `false` for `pRefreshView`
then call `RefreshView` to redraw the view.

<br>

## <a name="SetValueForKeyInNode"></a>SetValueForKeyInNode

**Type**: command

**Syntax**: `SetValueForKeyInNode <pNodeId>,<pKey>,<pValue>`

**Summary**: Sets the value of a custom key stored in a rows node array.

**Returns**: nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pNodeId` |  The node id or index array. |
| `pKey` |  The custom key. |
| `pValue` |  The value to assign to the key. |

**Description**:

See `SetValueForKeyInRow`.

<br>

## <a name="SetValueForKeyInRow"></a>SetValueForKeyInRow

**Type**: command

**Syntax**: `SetValueForKeyInRow <pRow>,<pKey>,<pValue>`

**Summary**: Sets the value of a custom key stored in a row's node array.

**Returns**: nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pRow` |  The target row. |
| `pKey` |  The custom key. |
| `pValue` |  The value to assign to the key. |

**Description**:

This function allow you to set the value of a key in the node array that is
not one of the built-in properties `id`, `type`, `expanded`, `is leaf`, `children`,
`level`, and `child count`.

<br>

## <a name="ShowNode"></a>ShowNode

**Type**: command

**Syntax**: `ShowNode <pNode>,<pRefreshView>`

**Summary**: Expands any tree nodes necessary so that the node can be seen.

**Returns**: empty

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pNode` |  The node `id` or the node index array. |
| `pRefreshView` |  Pass in false to keep the view from being refreshed. |

**Description**:

By default the DataView will be redrawn after calling this handler and the node will
be scrolled into view. If you pass in `false` for `pRefreshView`
then call `RefreshView` to redraw the view and `ScrollRowIntoView` to scroll
the row into view.

<br>

## <a name="ToggleNodeIsExpanded"></a>ToggleNodeIsExpanded

**Type**: command

**Syntax**: `ToggleNodeIsExpanded <pNode>,<pLevelsDown>,<pRefreshView>`

**Summary**: Toggles the expanded state of a node.

**Returns**: empty

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pNode` |  The node `id` or the node index array. |
| `pLevelsDown` |  How many levels to toggle. Empty or 0 only toggles pRow. -1 toggles all. Positive number affects that many levels down. |
| `pRefreshView` |  Pass in false to keep the view from being refreshed. |

**Description**:

See `SetRowIsExpanded`.

<br>

## <a name="ToggleRowIsExpanded"></a>ToggleRowIsExpanded

**Type**: command

**Syntax**: `ToggleRowIsExpanded <pRow>,<pLevelsDown>,<pRefreshView>`

**Summary**: Toggles the expanded state of a row.

**Returns**: Nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pRow` |  The row to toggle. |
| `pLevelsDown` |  How many levels to toggle. Empty or 0 only toggles pRow. -1 toggles all. Positive number affects that many levels down. |
| `pRefreshView` |  Pass in false to keep the view from being refreshed. |

**Description**:

See `SetRowIsExpanded`.


