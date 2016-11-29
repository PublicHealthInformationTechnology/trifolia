﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Trifolia.DB
{
    public partial class TemplateType
    {
        public static List<TemplateType> GetAll()
        {
            using (IObjectRepository tdb = DBContext.Create())
            {
                return tdb.TemplateTypes.ToList();
            }
        }

        public static List<TemplateType> GetIgTypeTemplateTypes(int implementationGuideTypeId)
        {
            using (IObjectRepository tdb = DBContext.Create())
            {
                return tdb.TemplateTypes
                    .Where(y => y.ImplementationGuideTypeId == implementationGuideTypeId)
                    .ToList();
            }
        }
    }
}
