discard """
  cmd: '''nim c --gc:regions $file'''
  output: '''
finalized
finalized
'''
"""

proc finish(o: RootRef) =
  echo "finalized"

withScratchRegion:
  var test: RootRef
  new(test, finish)

var
  mr: MemRegion
  test: RootRef

withRegion(mr):
  new(test, finish)

deallocAll(mr)
