local plugin = require("oz")

describe("setup", function()
  it("works with default", function()
    assert(plugin.engine_path() == "ozengine", "getting the ozenginepath")
  end)

  it("works with custom var", function()
    plugin.setup({ opt = { ozengine_path = "notapath" } })
    assert(plugin.engine_path() == "notapath", "getting a custom ozenginepath")
  end)
end)
