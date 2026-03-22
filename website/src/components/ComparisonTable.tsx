export function ComparisonTable({
  features,
}: {
  features: {
    name: string;
    macroMaxxing: boolean | string;
    others: boolean | string;
  }[];
}) {
  const renderCell = (value: boolean | string) => {
    if (typeof value === "string") return value;
    return value ? (
      <span className="text-brand-green text-lg">✓</span>
    ) : (
      <span className="text-gray-500 text-lg">✗</span>
    );
  };

  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse">
        <thead>
          <tr className="border-b border-white/10">
            <th className="text-left py-4 px-4 text-gray-400 font-medium text-sm">
              Feature
            </th>
            <th className="text-center py-4 px-4 text-brand-purple font-semibold text-sm">
              Macro Maxxing
            </th>
            <th className="text-center py-4 px-4 text-gray-400 font-medium text-sm">
              Other Apps
            </th>
          </tr>
        </thead>
        <tbody>
          {features.map((feature, i) => (
            <tr
              key={i}
              className="border-b border-white/5 hover:bg-white/[0.02]"
            >
              <td className="py-3 px-4 text-sm text-gray-300">
                {feature.name}
              </td>
              <td className="py-3 px-4 text-center">
                {renderCell(feature.macroMaxxing)}
              </td>
              <td className="py-3 px-4 text-center">
                {renderCell(feature.others)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
