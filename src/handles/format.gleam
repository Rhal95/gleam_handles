import gleam/int
import gleam/string
import handles/error

type Position {
  Position(index: Int, row: Int, col: Int)
  OutOfBounds
}

fn resolve_position(
  input: String,
  target_index: Int,
  current: Position,
) -> Position {
  case current {
    Position(index, row, col) if index == target_index ->
      Position(target_index, row, col)
    Position(index, row, col) ->
      case string.first(input) {
        Ok(char) ->
          case char {
            "\n" ->
              resolve_position(
                string.drop_start(input, 1),
                target_index,
                Position(index + 1, row + 1, 0),
              )
            _ ->
              resolve_position(
                string.drop_start(input, 1),
                target_index,
                Position(index + 1, row, col + 1),
              )
          }
        Error(_) -> OutOfBounds
      }
    OutOfBounds -> OutOfBounds
  }
}

fn transform_error(template: String, offset: Int, message: String) {
  case resolve_position(template, offset, Position(0, 0, 0)) {
    Position(_, row, col) ->
      Ok(
        message
        <> " (row="
        <> int.to_string(row)
        <> ", col="
        <> int.to_string(col)
        <> ")",
      )
    OutOfBounds -> Error(Nil)
  }
}

pub fn format_tokenizer_error(
  error: error.TokenizerError,
  template: String,
) -> Result(String, Nil) {
  case error {
    error.UnbalancedTag(index) ->
      transform_error(template, index, "Tag is missing closing braces }}")
    error.MissingArgument(index) ->
      transform_error(template, index, "Tag is missing an argument")
    error.MissingBlockKind(index) ->
      transform_error(template, index, "Tag is missing a block kind")
    error.MissingPartialId(index) ->
      transform_error(template, index, "Tag is missing a partial id")
    error.UnexpectedBlockKind(index) ->
      transform_error(template, index, "Tag is of an unknown block kind")
    error.UnexpectedMultipleArguments(index) ->
      transform_error(template, index, "Tag is receiving too many arguments")
    error.UnexpectedArgument(index) ->
      transform_error(template, index, "Tag is receiving too many arguments")
    error.UnbalancedBlock(index) ->
      transform_error(
        template,
        index,
        "Tag is a block but is missing its corresponding end tag",
      )
    error.UnexpectedBlockEnd(index) ->
      transform_error(
        template,
        index,
        "Tag is a block end but is missing its corresponsing opening tag",
      )
  }
}

pub fn format_runtime_error(
  error: error.RuntimeError,
  template: String,
) -> Result(String, Nil) {
  case error {
    error.UnexpectedType(index, path, got, expected) ->
      transform_error(
        template,
        index,
        "Unexpected type of property "
          <> string.join(path, ".")
          <> ", extepced "
          <> string.join(expected, " or ")
          <> " but found found "
          <> got,
      )
    error.UnknownProperty(index, path) ->
      transform_error(
        template,
        index,
        "Unable to resolve property " <> string.join(path, "."),
      )
    error.UnknownPartial(index, id) ->
      transform_error(template, index, "Unknown partial " <> id)
  }
}
