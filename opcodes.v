@[translated]
module main

@[c:'sqlite3OpcodeName']
fn sqlite3_opcode_name(i int) &i8 {
	if !sqlite3_opcode_name_az_name_inited {
		c2v_static_init := [c'Savepoint', c'AutoCommit', c'Transaction', c'Checkpoint',
			c'JournalMode', c'Vacuum', c'VFilter', c'VUpdate', c'Init', c'Goto', c'Gosub',
			c'InitCoroutine', c'Yield', c'MustBeInt', c'Jump', c'Once', c'If', c'IfNot', c'IsType',
			c'Not', c'IfNullRow', c'SeekLT', c'SeekLE', c'SeekGE', c'SeekGT', c'IfNotOpen',
			c'IfNoHope', c'NoConflict', c'NotFound', c'Found', c'SeekRowid', c'NotExists', c'Last',
			c'IfSizeBetween', c'SorterSort', c'Sort', c'Rewind', c'IfEmpty', c'SorterNext', c'Prev',
			c'Next', c'IdxLE', c'IdxGT', c'Or', c'And', c'IdxLT', c'IdxGE', c'IFindKey',
			c'RowSetRead', c'RowSetTest', c'Program', c'IsNull', c'NotNull', c'Ne', c'Eq', c'Gt',
			c'Le', c'Lt', c'Ge', c'ElseEq', c'FkIfZero', c'IfPos', c'IfNotZero', c'DecrJumpZero',
			c'IncrVacuum', c'VNext', c'Filter', c'PureFunc', c'Function', c'Return', c'EndCoroutine',
			c'HaltIfNull', c'Halt', c'Integer', c'Int64', c'String', c'BeginSubrtn', c'Null',
			c'SoftNull', c'Blob', c'Variable', c'Move', c'Copy', c'SCopy', c'IntCopy', c'FkCheck',
			c'ResultRow', c'CollSeq', c'AddImm', c'RealAffinity', c'Cast', c'Permutation', c'Compare',
			c'IsTrue', c'ZeroOrNull', c'Offset', c'Column', c'TypeCheck', c'Affinity', c'MakeRecord',
			c'Count', c'ReadCookie', c'SetCookie', c'BitAnd', c'BitOr', c'ShiftLeft', c'ShiftRight',
			c'Add', c'Subtract', c'Multiply', c'Divide', c'Remainder', c'Concat', c'ReopenIdx',
			c'OpenRead', c'BitNot', c'OpenWrite', c'OpenDup', c'String8', c'OpenAutoindex',
			c'OpenEphemeral', c'SorterOpen', c'SequenceTest', c'OpenPseudo', c'Close', c'ColumnsUsed',
			c'SeekScan', c'SeekHit', c'Sequence', c'NewRowid', c'Insert', c'RowCell', c'Delete',
			c'ResetCount', c'SorterCompare', c'SorterData', c'RowData', c'Rowid', c'NullRow',
			c'SeekEnd', c'IdxInsert', c'SorterInsert', c'IdxDelete', c'DeferredSeek', c'IdxRowid',
			c'FinishSeek', c'Destroy', c'Clear', c'ResetSorter', c'CreateBtree', c'SqlExec',
			c'ParseSchema', c'LoadAnalysis', c'DropTable', c'Real', c'DropIndex', c'DropTrigger',
			c'IntegrityCk', c'RowSetAdd', c'Param', c'FkCounter', c'MemMax', c'OffsetLimit',
			c'AggInverse', c'AggStep', c'AggStep1', c'AggValue', c'AggFinal', c'Expire',
			c'CursorLock', c'CursorUnlock', c'TableLock', c'VBegin', c'VCreate', c'VDestroy',
			c'VOpen', c'VCheck', c'VInitIn', c'VColumn', c'VRename', c'Pagecount', c'MaxPgcnt',
			c'ClrSubtype', c'GetSubtype', c'SetSubtype', c'FilterAdd', c'Trace', c'CursorHint',
			c'ReleaseReg', c'Noop', c'Explain', c'Abortable']
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_opcode_name_az_name[c2v_i_0] = c2v_element_0
		}
		sqlite3_opcode_name_az_name_inited = true
	}

	return sqlite3_opcode_name_az_name[i]
}
